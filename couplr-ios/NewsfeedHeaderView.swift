//
//  NewsfeedHeaderView.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 3/26/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class NewsfeedHeaderView: UIView {

    let headerLabel = UILabel()
    let nameSwitch = UISwitch()
    let bottomBorder = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let frameWidth = frame.size.width
        let frameHeight = frame.size.height
        
        bottomBorder.frame = CGRectMake(kProfileDetailViewBottomBorderWidth, frameHeight, frame.size.width - kProfileDetailViewBottomBorderWidth, kProfileDetailViewBottomBorderHeight)
        bottomBorder.backgroundColor = UIColor.grayColor().CGColor
        
        nameSwitch.frame = CGRectMake(frameWidth-nameSwitch.frame.width-10, (frameHeight/2)-(nameSwitch.frame.height/2), nameSwitch.frame.width, nameSwitch.frame.height)
        
        headerLabel.frame = CGRectMake(20, 0, frameWidth-nameSwitch.frame.width-10, frameHeight)
        
        addSubview(headerLabel)
        addSubview(nameSwitch)
        layer.addSublayer(bottomBorder)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
