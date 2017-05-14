//
//  PhotoCollectionViewCell.swift
//  Virtual Tourist
//
//  Created by Ali Kayhan on 21/02/2017.
//  Copyright © 2017 Ali Kayhan. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    
    var imageView = UIImageView()
    var activityIndicator = UIActivityIndicatorView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        imageView.frame = contentView.frame
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        activityIndicator.activityIndicatorViewStyle = .whiteLarge
        activityIndicator.center = CGPoint(x: frame.size.width/2, y: frame.size.height/2)
        activityIndicator.hidesWhenStopped = true
        
        contentView.addSubview(imageView)
        contentView.addSubview(activityIndicator)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
