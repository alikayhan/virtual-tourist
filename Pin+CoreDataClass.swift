//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Ali Kayhan on 26/02/2017.
//  Copyright © 2017 Ali Kayhan. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    
    convenience init(latitude: Double, longitude: Double, insertInto context: NSManagedObjectContext) {
        guard let entity = NSEntityDescription.entity(forEntityName: "Pin", in: context) else {
            fatalError("Unable to find entity name - Pin")
        }
        
        self.init(entity: entity, insertInto: context)
        self.latitude = latitude
        self.longitude = longitude
        self.photosPage = Int16(1)
    }

}
