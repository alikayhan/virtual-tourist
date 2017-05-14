//
//  GCDBlackBox.swift
//  Virtual Tourist
//
//  Created by Ali Kayhan on 14/02/2017.
//  Copyright © 2017 Ali Kayhan. All rights reserved.
//

import Foundation

func performUIUpdatesOnMain (updates: @escaping () -> Void) {
    DispatchQueue.main.async {
        updates()
    }
}
