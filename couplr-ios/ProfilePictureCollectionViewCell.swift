//
//  ProfilePictureCollectionViewCell.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/30/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class ProfilePictureCollectionViewCell: UICollectionViewCell {

    let imageView = UIImageView()
    
    var userName: String = ""
    var overrideLayerSelection: Bool = false
    let transparentLayer = UIView()
    let nameLabel = UILabel()
    var width: CGFloat = 100
    var height: CGFloat = 100
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        width = frame.width
        height = frame.height

        layer.masksToBounds = true
        layer.cornerRadius = 0.15 * width
        
        imageView.frame = CGRectMake(0, 0, width, height).withMargin(horizontal: 3, vertical: 3)
        imageView.backgroundColor = UIColor.whiteColor()
        imageView.layer.cornerRadius = 0.15 * width - 1
        imageView.layer.borderColor = UIColor.grayColor().CGColor
        imageView.layer.borderWidth = 0.5
        imageView.clipsToBounds = true
        
        contentView.addSubview(imageView)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func addTransparentLayerWithName(name: String) {
        transparentLayer.frame = CGRectMake(0, 0, width, height).withMargin(horizontal: 2, vertical: 2)
        transparentLayer.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        transparentLayer.layer.masksToBounds = true
        transparentLayer.layer.cornerRadius = 0.15 * width
        
        nameLabel.numberOfLines = 0
        nameLabel.frame = CGRectMake(0, 0, width, height).withMargin(horizontal: 2, vertical: 2)
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
            }, completion: { (value: Bool) in
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
