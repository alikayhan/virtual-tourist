//
//  PhotoAlbumViewController.swift
//  Virtual Tourist
//
//  Created by Ali Kayhan on 22/09/16.
//  Copyright © 2016 Ali Kayhan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Properties
    var pin: Pin!
    var selectedPhotosIndexes = [IndexPath]()
    var deletePhotosModeIsOn: Bool = false
    var stack: CoreDataStack!
    var flickrClientParameterValuePage: Int!

    var fetchedResultsController : NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            // Whenever the frc changes, we execute the search and
            // reload the collection view
            fetchedResultsController?.delegate = self
            executeSearch()
            photoCollectionView?.reloadData()
        }
    }
    
    var blockOperations: [BlockOperation] = []
    
    // MARK: Deinit
    deinit {
        blockOperations.forEach { $0.cancel() }
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    // MARK: - Outlets
    @IBOutlet weak var pinMapView: MKMapView!
    @IBOutlet weak var photoCollectionView: UICollectionView!
    @IBOutlet weak var bottomButton: UIButton!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var noPhotosLabel: UILabel!
    
    // MARK: - Lifecycle Functions
    override func viewWillAppear(_ animated: Bool) {
        if let fc = fetchedResultsController {
            if fc.fetchedObjects?.count == 0 {
                searchPhotos(with: pin.latitude, and: pin.longitude)
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pinMapView.delegate = self
        
        photoCollectionView.register(PhotoCollectionViewCell.self, forCellWithReuseIdentifier: "PhotoCell")
        photoCollectionView.dataSource = self
        photoCollectionView.delegate = self
        photoCollectionView.allowsMultipleSelection = true
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        stack = appDelegate.stack
        
        noPhotosLabel.text = UIConstants.Title.NoImagesLabelTitle
        noPhotosLabel.isHidden = true
        
        configureBottomButtonByDeletePhotosMode(isOn: deletePhotosModeIsOn)
        configurePinMapView(with: pin.latitude, and: pin.longitude)
    }
    
    // This method is automatically called when the view transitions to another 
    // size and it invalidates the layout of the collection view.
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        flowLayout.invalidateLayout()
    }
    
    // MARK: - Actions
    @IBAction func bottomButtonPressed(_ sender: UIButton) {
        
        if deletePhotosModeIsOn {
            for indexPath in selectedPhotosIndexes {
                stack.context.delete(fetchedResultsController?.object(at: indexPath) as! Photo)
            }
            
            selectedPhotosIndexes.removeAll()
            deletePhotosModeIsOn = false
            configureBottomButtonByDeletePhotosMode(isOn: false)
            
        } else {
            self.noPhotosLabel.isHidden = true
            
            for object in (fetchedResultsController?.fetchedObjects)! {
                stack.context.delete(object as! NSManagedObject)
            }
            
            flickrClientParameterValuePage = flickrClientParameterValuePage + 1
            pin.photosPage = Int16(flickrClientParameterValuePage)
            
            searchPhotos(with: pin.latitude, and: pin.longitude)
        }
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.pinTintColor = .red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    // MARK: - Helper Functions
    
    fileprivate func searchPhotos(with lat: Double, and lon: Double) {
        setUI(enabled: false)
        
        let methodParameters = [
            FlickrClient.ParameterKeys.Method: FlickrClient.ParameterValues.SearchMethod,
            FlickrClient.ParameterKeys.APIKey: FlickrClient.ParameterValues.APIKey,
            FlickrClient.ParameterKeys.BoundingBox: bboxString(for: lat, and: lon),
            FlickrClient.ParameterKeys.SafeSearch: FlickrClient.ParameterValues.UseSafeSearch,
            FlickrClient.ParameterKeys.Extras: FlickrClient.ParameterValues.SmallURL,
            FlickrClient.ParameterKeys.Format: FlickrClient.ParameterValues.ResponseFormat,
            FlickrClient.ParameterKeys.NoJSONCallback: FlickrClient.ParameterValues.DisableJSONCallback,
            FlickrClient.ParameterKeys.PerPage: FlickrClient.ParameterValues.PerPage,
            FlickrClient.ParameterKeys.Page: String(flickrClientParameterValuePage)
        ]
        
        FlickrClient().shared.searchPhotos(with: methodParameters as [String : AnyObject]) { (photos, error) in
            print("Download has started")
            
            guard let photos = photos as? [[String : AnyObject]] else {
                return
            }
            
            print(photos.count)
            
            if photos.count == 0 {
                performUIUpdatesOnMain(updates: { 
                    self.photoCollectionView.isHidden = true
                    self.noPhotosLabel.isHidden = false
                    self.setUI(enabled: true)
                })
            } else {                
                
                for photo in photos {
                    let url = photo[FlickrClient.ResponseKeys.SmallURL] as! String
                    
                    let pinPhoto = Photo(image: UIImage(named:"PlaceholderImage")!, url: url, context: self.stack.context)
                    pinPhoto.pin = self.pin
                    
                }
                
                self.setUI(enabled: true)
            }
        }
    }
    
    fileprivate func bboxString(for lat: Double, and lon: Double) -> String {
        // Ensure bbox is bounded by minimum and maximums
        let minimumLon = max(lon - FlickrClient.SearchConstants.SearchBBoxHalfWidth, FlickrClient.SearchConstants.SearchLonRange.0)
        let minimumLat = max(lat - FlickrClient.SearchConstants.SearchBBoxHalfHeight, FlickrClient.SearchConstants.SearchLatRange.0)
        let maximumLon = min(lon + FlickrClient.SearchConstants.SearchBBoxHalfWidth, FlickrClient.SearchConstants.SearchLonRange.1)
        let maximumLat = min(lat + FlickrClient.SearchConstants.SearchBBoxHalfHeight, FlickrClient.SearchConstants.SearchLatRange.1)
        return "\(minimumLon),\(minimumLat),\(maximumLon),\(maximumLat)"
    }
}

// MARK: - PhotoAlbumViewController (Configure UI)

extension PhotoAlbumViewController {
    
    fileprivate func configureBottomButtonByDeletePhotosMode(isOn: Bool) {
        bottomButton.backgroundColor = UIColor.white
        
        if isOn {
            bottomButton.setTitle(UIConstants.Title.BottomButtonRemoveSelectedPicturesTitle, for: .normal)
        } else {
            bottomButton.setTitle(UIConstants.Title.BottomButtonNewCollectionTitle, for: .normal)
        }
    }
    
    fileprivate func configurePinMapView(with lat: Double, and lon: Double) {
        let annotation = MKPointAnnotation()
        annotation.coordinate.latitude = lat
        annotation.coordinate.longitude = lon
        
        let span = MKCoordinateSpanMake(UIConstants.Map.SpanValue, UIConstants.Map.SpanValue)
        let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: lat, longitude: lon), span: span)
        pinMapView.setRegion(region, animated: true)
        pinMapView.addAnnotation(annotation)
        pinMapView.isUserInteractionEnabled = false
    }
    
    fileprivate func setUI(enabled: Bool) {
        performUIUpdatesOnMain {
            self.bottomButton.isEnabled = enabled
            
            if enabled {
                self.bottomButton.alpha = 1.0
            } else {
                self.bottomButton.alpha = 0.5
            }
        }
    }
}


// MARK: - PhotoAlbumViewController (UICollectionViewDataSource)

extension PhotoAlbumViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let reuseIdentifier = "PhotoCell"
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! PhotoCollectionViewCell
        cell.backgroundColor = .red
        cell.imageView.image = UIImage(named: "PlaceholderImage")
        cell.imageView.alpha = CGFloat(UIConstants.PhotoCollectionView.UnselectedItemImageViewAlpha)
        cell.activityIndicator.startAnimating()
        
        if let photoObject = self.fetchedResultsController?.object(at: indexPath) as? Photo {
            if let imageData = photoObject.image {
                if imageData.isEqual(to: UIImagePNGRepresentation(UIImage(named: "PlaceholderImage")!)!) {
                    guard let url = photoObject.url else { return cell }
                    
                    FlickrClient().shared.downloadPhoto(with: url, completionHandlerForDownloadPhoto: { (imageData) in
                        if let imageData = imageData as? Data {
                            performUIUpdatesOnMain {
                                photoObject.image = UIImagePNGRepresentation(UIImage(data: imageData as Data)!) as NSData?
                                cell.imageView.image = UIImage(data: imageData as Data)
                                cell.activityIndicator.stopAnimating()
                            }
                        }
                    })
                } else {
                    performUIUpdatesOnMain {
                        cell.imageView.image = UIImage(data: imageData as Data)
                        cell.activityIndicator.stopAnimating()
                    }
                }
            }
        }
        return cell
    }
}


// MARK: - PhotoAlbumViewController (UICollectionViewDelegate)

extension PhotoAlbumViewController: UICollectionViewDelegate {
    
    // All cells are deselected at the beginning and when user selects a cell,
    // it is added to selectedPhotosIndexes.
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {        
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
            return
        }
        
        selectedPhotosIndexes.append(indexPath)
        performUIUpdatesOnMain(updates: { 
            cell.imageView.alpha = CGFloat(UIConstants.PhotoCollectionView.SelectedItemImageViewAlpha)
        })
        
        self.deletePhotosModeIsOn = true
        self.configureBottomButtonByDeletePhotosMode(isOn: self.deletePhotosModeIsOn)
        
    }
    
    // Only cells which are added to selectedPhotosIndexes can be deselected so deselected one
    // gets removed from selectedPhotosIndexes.
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? PhotoCollectionViewCell else {
            return
        }
        
        if let index = selectedPhotosIndexes.index(of: indexPath) {
            selectedPhotosIndexes.remove(at: index)
            
            performUIUpdatesOnMain(updates: {
                cell.imageView.alpha = CGFloat(UIConstants.PhotoCollectionView.UnselectedItemImageViewAlpha)
            })
            
            if selectedPhotosIndexes.isEmpty {
                self.deletePhotosModeIsOn = false
                self.configureBottomButtonByDeletePhotosMode(isOn: self.deletePhotosModeIsOn)
            }
        }
    }
}


// MARK: - PhotoAlbumViewController (UICollectionViewDelegateFlowLayout)

extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout {
    
    // This function is automatically called when the current flow layout is invalidated and
    // sets a new cell size appropriate to device's new orientation.
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return setupFlowLayout(spaceBetweenPhotoCells: CGFloat(UIConstants.PhotoCollectionView.SpaceBetweenItems), photosInARow: UIConstants.PhotoCollectionView.ItemsInARow).itemSize
    }
    
    // Helper function for setting flow layout up
    func setupFlowLayout(spaceBetweenPhotoCells: CGFloat, photosInARow: Int) -> UICollectionViewFlowLayout {
        let dimension = (view.frame.size.width - ((CGFloat(photosInARow - 1)) * spaceBetweenPhotoCells)) / CGFloat(photosInARow)
        
        flowLayout.minimumLineSpacing = spaceBetweenPhotoCells
        flowLayout.minimumInteritemSpacing = spaceBetweenPhotoCells
        flowLayout.itemSize = CGSize(width: dimension, height: dimension)
        
        return flowLayout
    }
}

// MARK: - PhotoAlbumViewController (NSFetchedResultsControllerDelegate)

extension PhotoAlbumViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        blockOperations.removeAll(keepingCapacity: false)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        
        switch type {
            case .insert:
                guard let newIndexPath = newIndexPath else { return }
                let op = BlockOperation { [weak self] in self?.photoCollectionView.insertItems(at: [newIndexPath]) }
                blockOperations.append(op)
                
            case .update:
                guard let newIndexPath = newIndexPath else { return }
                let op = BlockOperation { [weak self] in self?.photoCollectionView.reloadItems(at: [newIndexPath]) }
                blockOperations.append(op)
                
            case .move:
                guard let indexPath = indexPath else { return }
                guard let newIndexPath = newIndexPath else { return }
                let op = BlockOperation { [weak self] in self?.photoCollectionView.moveItem(at: indexPath, to: newIndexPath) }
                blockOperations.append(op)
                
            case .delete:
                guard let indexPath = indexPath else { return }
                let op = BlockOperation { [weak self] in self?.photoCollectionView.deleteItems(at: [indexPath]) }
                blockOperations.append(op)
        }
    }
    
    func controller(controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        
        switch type {
            case .insert:
                let op = BlockOperation { [weak self] in self?.photoCollectionView.insertSections(NSIndexSet(index: sectionIndex) as IndexSet) }
                blockOperations.append(op)
                
            case .update:
                let op = BlockOperation { [weak self] in self?.photoCollectionView.reloadSections(NSIndexSet(index: sectionIndex) as IndexSet) }
                blockOperations.append(op)
                
            case .delete:
                let op = BlockOperation { [weak self] in self?.photoCollectionView.deleteSections(NSIndexSet(index: sectionIndex) as IndexSet) }
                blockOperations.append(op)
                
            default: break
            
        }
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        photoCollectionView.performBatchUpdates({
            self.blockOperations.forEach { $0.start() }
        }, completion: { finished in
            self.blockOperations.removeAll(keepingCapacity: false)
        })
    }
}

// MARK: - PhotoAlbumViewController (Execute Search)

extension PhotoAlbumViewController {
    func executeSearch() {
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch let e as NSError {
                print("Error while trying to perform a search: \n\(e)\n\(String(describing: fetchedResultsController))")
            }
        }
    }
}
