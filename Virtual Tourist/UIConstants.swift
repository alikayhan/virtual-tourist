//
//  UIConstants.swift
//  Virtual Tourist
//
//  Created by Ali Kayhan on 07/01/2017.
//  Copyright © 2017 Ali Kayhan. All rights reserved.
//

import Foundation

struct UIConstants {
    
    // MARK: - Titles
    struct Title {
        
        // TravelLocationsMapViewController
        static let TravelLocationsMapViewControllerTitle = "Virtual Tourist"
        static let TapPinsToDeleteLabelTitle = "Tap Pins To Delete"
        
        static let BarButtonItemEditTitle = "Edit"
        static let BarButtonItemDoneTitle = "Done"
        
        // PhotoAlbumViewController
        static let BottomButtonNewCollectionTitle = "New Collection"
        static let NoImagesLabelTitle = "This pin has no images."
        static let BottomButtonRemoveSelectedPicturesTitle = "Remove Selected Pictures"
    }
    
    struct Map {
        static let SpanValue = 0.2
    }
    
    struct PhotoCollectionView {
        static let SpaceBetweenItems = 2.0
        static let ItemsInARow = 3
        static let SelectedItemImageViewAlpha = 0.2
        static let UnselectedItemImageViewAlpha = 1.0
    }
}
