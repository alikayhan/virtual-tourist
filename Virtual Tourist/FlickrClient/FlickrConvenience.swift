//
//  FlickrConvenience.swift
//  Virtual Tourist
//
//  Created by Ali Kayhan on 14/02/2017.
//  Copyright © 2017 Ali Kayhan. All rights reserved.
//

import Foundation

// MARK: - FlickrClient (Convenient Resource Methods)

extension FlickrClient {
    
    func searchPhotos(with parameters: [String : AnyObject], completionHandlerForSearchPhotos: @escaping (Any?, Error?) -> Void) {
        
        /* Make the request */
        taskForGETMethod(with: parameters) { (results, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForSearchPhotos(nil, NSError(domain: "getPhotos response check and parsing", code: 1, userInfo: userInfo))
            }
            
            /* GUARD: Did Flickr return a result? */
            guard let results = results else {
                completionHandlerForSearchPhotos(nil, error)
                return
            }
            
            /* GUARD: Did Flickr return an error (stat != ok)? */
            guard let stat = results[ResponseKeys.Status] as? String, stat == ResponseValues.OKStatus else {
                sendError("Flickr API returned an error. See error code and message in \(results)")
                return
            }
            
            /* GUARD: Is "photos" key in our result? */
            guard let photosDictionary = results[ResponseKeys.Photos] as? [String:AnyObject] else {
                sendError("Cannot find keys '\(ResponseKeys.Photos)' in \(results)")
                return
            }
            
            /* GUARD: Is "photo" key in our photosDictionary? */
            guard let photos = photosDictionary[FlickrClient.ResponseKeys.Photo] as? [[String : AnyObject]] else {
                sendError("Could not parse getPhotos")
                return
            }
            
            /* Send the desired value(s) to completion handler */
            completionHandlerForSearchPhotos(photos, nil)
        }
    }
    
    func downloadPhoto(with imageURL: String, completionHandlerForDownloadPhoto: @escaping (Any?) -> Void) {
        guard let url = URL(string: imageURL) else {
            return
        }
        
        // Download photos in a background thread
        DispatchQueue.global(qos: .background).async {
            do {
                let imageData = try Data(contentsOf: url)
                completionHandlerForDownloadPhoto(imageData)
            } catch {
                print(error.localizedDescription)
                completionHandlerForDownloadPhoto(nil)
            }
        }
    }
}
