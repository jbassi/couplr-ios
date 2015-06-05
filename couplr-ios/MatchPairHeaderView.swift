//
//  MatchPairHeaderView.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 3/26/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class MatchPairHeaderView: UIView {

    let headerLabel = UILabel()
    let nameToggleButton = UIButton()
    let bottomBorder = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let frameWidth = frame.size.width
        let frameHeight = frame.size.height
        
        bottomBorder.frame = CGRectMake(kProfileDetailViewBottomBorderWidth, frameHeight, frame.size.width - kProfileDetailViewBottomBorderWidth, kProfileDetailViewBottomBorderHeight)
        bottomBorder.backgroundColor = UIColor.grayColor().CGColor
        
        let namesLabelWidth: CGFloat = 66
        let namesLabelHeight: CGFloat = 30
        let namesLabelY: CGFloat = (frameHeight / 2) - (namesLabelHeight / 2)
        let namesLabelX: CGFloat = frameWidth - nameToggleButton.frame.width - namesLabelWidth - 10
        
        headerLabel.frame = CGRectMake(20, 0, frameWidth-nameToggleButton.frame.width-10, frameHeight)
        
        let nameToggleButtonLength: CGFloat = 60
        let nameToggleButtonInsets: CGFloat = 0.15 * nameToggleButtonLength
        nameToggleButton.frame = CGRectMake(frameWidth - nameToggleButtonLength - 10, (frameHeight - nameToggleButtonLength) / 2, nameToggleButtonLength, nameToggleButtonLength)
        nameToggleButton.backgroundColor = UIColor.whiteColor()
        nameToggleButton.layer.cornerRadius = nameToggleButtonLength / 2 - 1
        nameToggleButton.layer.borderColor = UIColor(white: 0.67, alpha: 1).CGColor
        nameToggleButton.layer.borderWidth = 0.5
        nameToggleButton.setImage(UIImage(named: "matchview-names"), forState: .Normal)
        nameToggleButton.setImage(UIImage(named: "matchview-names-highlight"), forState: .Selected)
        nameToggleButton.setImage(UIImage(named: "matchview-names-highlight"), forState: .Highlighted)
        nameToggleButton.imageEdgeInsets = UIEdgeInsetsMake(nameToggleButtonInsets, nameToggleButtonInsets, nameToggleButtonInsets, nameToggleButtonInsets)
        nameToggleButton.clipsToBounds = true
        
        addSubview(headerLabel)
        addSubview(nameToggleButton)
        layer.addSublayer(bottomBorder)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
