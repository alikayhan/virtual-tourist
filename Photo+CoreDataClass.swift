//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Ali Kayhan on 26/02/2017.
//  Copyright © 2017 Ali Kayhan. All rights reserved.
//

import Foundation
import CoreData
import UIKit

@objc(Photo)
public class Photo: NSManagedObject {
    
    convenience init(image: UIImage, url: String, context: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Photo", in: context) else {
            fatalError("Unable to find entity name - Photo")
        }
        
        self.init(entity: entity, insertInto: context)
        self.creationDate = Date()
        self.url = url
        self.image = UIImagePNGRepresentation(image) as NSData?
    }

}
