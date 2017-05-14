//
//  FlickerClient.swift
//  Virtual Tourist
//
//  Created by Ali Kayhan on 12/02/2017.
//  Copyright © 2017 Ali Kayhan. All rights reserved.
//

import Foundation

class FlickrClient: NSObject {
    
    // MARK: - Properties
    
    // Shared session
    var session = URLSession.shared
    
    // Shared instance
    var shared: FlickrClient {
        get {
            struct Singleton {
                static var sharedInstance = FlickrClient()
            }
            return Singleton.sharedInstance
        }
    }
    
    // Flickr API Key
    var flickrAPIKey: String!
    
    // MARK: - Initializers
    override init() {
        super.init()
        
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            if let keys = NSDictionary(contentsOfFile: path) {
                flickrAPIKey = keys["flickrAPIKey"] as! String
            }            
        }
    }
    
    // MARK: - GET
    @discardableResult func taskForGETMethod(with parameters: [String : AnyObject] = [:], completionHandlerForGET: @escaping (AnyObject?, Error?) -> Void) -> URLSessionDataTask {
        
        /* Build the URL, Configure the request */
        let request = URLRequest(url: flickrURL(from: parameters))
        
        /* Make the request */
        let task = session.dataTask(with: request) { (data, response, error) in
            
            func sendError(_ error: String) {
                print(error)
                let userInfo = [NSLocalizedDescriptionKey : error]
                completionHandlerForGET(nil, NSError(domain: "taskForGETMethod", code: 1, userInfo: userInfo))
            }
            
            /* Was there an error? */
            guard (error == nil) else {
                sendError("There was an error with your request: \(String(describing: error))")
                return
            }
            
            /* Did we get a successful 2XX response? */
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            /* Was there any data returned? */
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            /* Parse the data and use the data (happens in completion handler) */
            self.convert(data, with: completionHandlerForGET)
        }
        
        /* Start the request */
        task.resume()
        
        return task
    }
    
    // MARK: - Helpers
    
    // Given raw JSON, return a usable Foundation object
    private func convert(_ data: Data, with completionHandlerForConvertData: (AnyObject?, Error?) -> Void) {
        
        var parsedResult: Any!
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandlerForConvertData(nil, NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: userInfo))
        }
        
        completionHandlerForConvertData(parsedResult as AnyObject?, nil)
    }
    
    // Create URL from parameters
    private func flickrURL(from parameters: [String : AnyObject], with pathExtension: String? = nil) -> URL {
        
        var components = URLComponents()
        components.scheme = FlickrClient.URLConstants.APIScheme
        components.host = FlickrClient.URLConstants.APIHost
        components.path = FlickrClient.URLConstants.APIPath + (pathExtension ?? "")
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}
