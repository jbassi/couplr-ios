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
    let nameSwitch = UISwitch()
    let namesLabel = UILabel()
    let bottomBorder = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let frameWidth = frame.size.width
        let frameHeight = frame.size.height
        
        bottomBorder.frame = CGRectMake(kProfileDetailViewBottomBorderWidth, frameHeight, frame.size.width - kProfileDetailViewBottomBorderWidth, kProfileDetailViewBottomBorderHeight)
        bottomBorder.backgroundColor = UIColor.grayColor().CGColor
        
        nameSwitch.frame = CGRectMake(frameWidth-nameSwitch.frame.width-10, (frameHeight/2)-(nameSwitch.frame.height/2), nameSwitch.frame.width, nameSwitch.frame.height)
        
        namesLabel.text = "Names:"
        let namesLabelWidth: CGFloat = 66
        let namesLabelHeight: CGFloat = 30
        let namesLabelY: CGFloat = (frameHeight / 2) - (namesLabelHeight / 2)
        let namesLabelX: CGFloat = frameWidth - nameSwitch.frame.width - namesLabelWidth - 10
        namesLabel.frame = CGRectMake(namesLabelX, namesLabelY, namesLabelWidth, namesLabelHeight)
        
        headerLabel.frame = CGRectMake(20, 0, frameWidth-nameSwitch.frame.width-10, frameHeight)
        
        addSubview(headerLabel)
        addSubview(nameSwitch)
        addSubview(namesLabel)
        layer.addSublayer(bottomBorder)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}
