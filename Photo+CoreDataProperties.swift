//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Ali Kayhan on 26/02/2017.
//  Copyright © 2017 Ali Kayhan. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var image: NSData?
    @NSManaged public var creationDate: Date?
    @NSManaged public var url: String?
    @NSManaged public var pin: Pin?

}
