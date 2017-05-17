//
//  TravelLocationsMapViewController.swift
//  Virtual Tourist
//
//  Created by Ali Kayhan on 22/09/16.
//  Copyright © 2016 Ali Kayhan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class TravelLocationsMapViewController: UIViewController, MKMapViewDelegate {
    
    // MARK: - Properties
    var deletePinsModeIsOn: Bool = false
    var selectedPin: Pin!
    var stack: CoreDataStack!
    
    // MARK: - Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var tapPinsToDeleteLabel: UILabel!
    @IBOutlet weak var barButton: UIBarButtonItem!
    
    // MARK: - Lifecycle Functions
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        adjustMapRegion()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        configureTapPinsToDeleteLabel()
        configureLongPressGestureRecognizer()
        configureBarButtonByDeletePinsMode(isOn: deletePinsModeIsOn)
        navigationItem.title = UIConstants.Title.TravelLocationsMapViewControllerTitle
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        stack = appDelegate.stack
        
        populateMap()
    }
    
    // MARK: - Actions
    @IBAction func switchMode(_ sender: UIBarButtonItem) {
        deletePinsModeIsOn = !deletePinsModeIsOn
        deletePinsMode(isOn: deletePinsModeIsOn)
    }
    
    // MARK: - MKMapViewDelegate
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.animatesDrop = true
            pinView?.pinTintColor = UIColor.red
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let selectedAnnotation = view.annotation else {
            return
        }
        
        mapView.deselectAnnotation(selectedAnnotation, animated: true)
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        let predicate = NSPredicate(format: "latitude == %@ AND longitude == %@", argumentArray: [selectedAnnotation.coordinate.latitude, selectedAnnotation.coordinate.longitude])
        
        fetchRequest.predicate = predicate
        
        do {
            let results = try stack.context.fetch(fetchRequest) as? [Pin]
            selectedPin = results![0]
        } catch {
            print(error.localizedDescription)
            return
        }
        
        if deletePinsModeIsOn {
            performUIUpdatesOnMain {
                mapView.removeAnnotation(selectedAnnotation)
            }
            
            stack.context.delete(selectedPin)
            
            // Save context after pin is deleted
            do {
                try self.stack.saveContext()
            } catch {
                print(error.localizedDescription)
            }
            
            return
        } else {
            performSegue(withIdentifier: "UserDidTapAPin", sender: nil)
            
        }
    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        saveMapRegion()
    }
    
    // MARK: - Prepare For Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let photoAlbumViewController = segue.destination as! PhotoAlbumViewController
        photoAlbumViewController.pin = selectedPin
        photoAlbumViewController.flickrClientParameterValuePage = Int(selectedPin.photosPage)
        
        let fr = NSFetchRequest<NSFetchRequestResult>(entityName: "Photo")        
        fr.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        fr.predicate = NSPredicate(format: "pin = %@", argumentArray: [selectedPin])
        
        let fc = NSFetchedResultsController(fetchRequest: fr, managedObjectContext: stack.context, sectionNameKeyPath: nil, cacheName: nil)
        
        photoAlbumViewController.fetchedResultsController = fc
    }

    // MARK: - Helper Functions
    fileprivate func deletePinsMode(isOn: Bool) {
        tapPinsToDeleteLabel.isHidden = !isOn
        configureBarButtonByDeletePinsMode(isOn: isOn)
    }
    
    fileprivate func configureTapPinsToDeleteLabel() {
        tapPinsToDeleteLabel.backgroundColor = UIColor.red
        tapPinsToDeleteLabel.textColor = UIColor.white
        tapPinsToDeleteLabel.text = UIConstants.Title.TapPinsToDeleteLabelTitle
        tapPinsToDeleteLabel.textAlignment = .center
        tapPinsToDeleteLabel.isHidden = !deletePinsModeIsOn
    }
    
    fileprivate func configureBarButtonByDeletePinsMode(isOn: Bool) {
        if isOn {
            barButton.style = .done
            barButton.title = UIConstants.Title.BarButtonItemDoneTitle
        } else {
            barButton.style = .plain
            barButton.title = UIConstants.Title.BarButtonItemEditTitle
        }
    }
    
    fileprivate func configureLongPressGestureRecognizer() {
        let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(addAnnotation(gestureRecognizer:)))
        longPressGestureRecognizer.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGestureRecognizer)
    }
    
    @objc fileprivate func addAnnotation(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            
            performUIUpdatesOnMain {
                let annotation = MKPointAnnotation()
                annotation.coordinate = touchCoordinate
                
                self.mapView.addAnnotation(annotation)
            }
            
            savePin(at: touchCoordinate)
        }
    }
    
    fileprivate func savePin(at touchCoordinate: CLLocationCoordinate2D) {
        
        // Use Core Data concurrency principles (background writer & main queue reader)
        stack.performBackgroundBatchOperation { (workerContext) in
            _ = Pin(latitude: touchCoordinate.latitude, longitude: touchCoordinate.longitude, insertInto: workerContext)
            
            // In order not to lose pin data in a case of crash etc, context is saved immediately
            // without waiting for auto save.
            do {
                try self.stack.saveContext()
            } catch {
                print(error.localizedDescription)
            }
        }       
    }
    
    // MARK: - Populate Map
    fileprivate func populateMap() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Pin")
        do {
            if let pins = try? stack.context.fetch(fetchRequest) as! [Pin] {
                var pinAnnotations = [MKPointAnnotation]()
                
                for pin in pins {
                    let latitude = CLLocationDegrees(pin.latitude)
                    let longitude = CLLocationDegrees(pin.longitude)
                    let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                    let annotation = MKPointAnnotation()
                    annotation.coordinate = coordinate

                    pinAnnotations.append(annotation)
                }

                mapView.addAnnotations(pinAnnotations)
            } else {
                print("Fetch request for populateMap method has failed")
            }
        }
    }
    
    // MARK: - Adjust and Save Map Region
    fileprivate func adjustMapRegion() {
        if let centerLatitude = UserDefaults.standard.value(forKey: "centerLatitude"), let centerLongitude = UserDefaults.standard.value(forKey: "centerLongitude"), let spanLatitude = UserDefaults.standard.value(forKey: "spanLatitude"), let spanLongitude = UserDefaults.standard.value(forKey: "spanLongitude") {
            
            let span = MKCoordinateSpanMake(spanLatitude as! CLLocationDegrees, spanLongitude as! CLLocationDegrees)
            let region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: centerLatitude as! CLLocationDegrees, longitude: centerLongitude as! CLLocationDegrees), span: span)
            
            mapView.setRegion(region, animated: true)
        }
    }
    
    fileprivate func saveMapRegion() {
        UserDefaults.standard.set(mapView.region.center.latitude, forKey: "centerLatitude")
        UserDefaults.standard.set(mapView.region.center.longitude, forKey: "centerLongitude")
        UserDefaults.standard.set(mapView.region.span.latitudeDelta, forKey: "spanLatitude")
        UserDefaults.standard.set(mapView.region.span.longitudeDelta, forKey: "spanLongitude")
        
        UserDefaults.standard.synchronize()
    }
}
