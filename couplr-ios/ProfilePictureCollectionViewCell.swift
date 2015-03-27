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
    var overrideLayerSelection: Bool = false
    let transparentLayer = UIView()
    let nameLabel = UILabel()
    
    func addTransparentLayerWithName(name:String) {
        transparentLayer.frame = CGRectMake(4, 4, 92, 92)
        transparentLayer.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        transparentLayer.layer.masksToBounds = true
        transparentLayer.layer.cornerRadius = 10
        
        nameLabel.numberOfLines = 0
        nameLabel.frame = CGRectMake(0, 0, 92, 92)
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
    
    func addTransparentLayer() {
        addTransparentLayerWithName(userName)
    }
    
    override var selected: Bool {
        willSet(newValue) {
            if !overrideLayerSelection {
                newValue ? addTransparentLayerWithName(userName) : removeTransparentLayer()
            }
        }
    }
    
}
