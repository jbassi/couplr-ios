//
//  ProfilePictureCollectionViewCell.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/30/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class ProfilePictureCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: ProfilePictureImageView!
    
    var userName: String = ""
    let transparentLayer = UIView()
    let nameLabel = UILabel()
    
    func addTransparentLayerWithName(name:String) {
        transparentLayer.frame = contentView.frame
        transparentLayer.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        
        nameLabel.numberOfLines = 0
        nameLabel.frame = CGRectMake(0, 0, 100, 100)
        nameLabel.textColor = UIColor.whiteColor()
        nameLabel.font = UIFont.boldSystemFontOfSize(12)
        nameLabel.text = name
        nameLabel.textAlignment = NSTextAlignment.Center
        
        transparentLayer.addSubview(nameLabel)
        contentView.addSubview(transparentLayer)
    }
    
    func removeTransparentLayer() {
        UIView.animateWithDuration(kProfilePictureCollectionViewCellHideAnimationDuration, animations: {
            self.transparentLayer.backgroundColor = UIColor.clearColor()
            self.nameLabel.textColor = UIColor.clearColor()
            }, completion: { (value:Bool) in
                self.transparentLayer.removeFromSuperview()
                self.nameLabel.removeFromSuperview()
        })
    }
    
    override var selected: Bool {
        willSet(newValue) {
            newValue ? addTransparentLayerWithName(userName) : removeTransparentLayer()
        }
    }
    
}
