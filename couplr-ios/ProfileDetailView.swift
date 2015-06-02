//
//  ProfileDetailView.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 1/5/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import QuartzCore

class ProfileDetailView: UIView {
    
    let profilePictureView = UIImageView()
    let profileNameLabel = UILabel()
    let recentMatchesButton = UIButton()
    let bottomBorder = CALayer()
    let backButton = UIButton()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let frameWidth = frame.size.width
        let frameHeight = frame.size.height
        
        let kProfileNameLabelHeightRatio: CGFloat = 0.4
        
        let profilePictureMargin: CGFloat = 0.1 * frameHeight
        let profilePictureFrame = CGRectMake(0, 0, frameHeight, frameHeight) // Frame height is not a typo.
        let shadowView = UIView(frame: profilePictureFrame.withMargin(horizontal: profilePictureMargin, vertical: profilePictureMargin))
        shadowView.layer.shadowColor = UIColor.blackColor().CGColor
        shadowView.layer.shadowOffset = CGSizeZero
        shadowView.layer.shadowOpacity = 0.5
        shadowView.layer.shadowRadius = 2

        profilePictureView.frame = shadowView.bounds
        profilePictureView.backgroundColor = UIColor.whiteColor()
        profilePictureView.layer.cornerRadius = shadowView.frame.width / 2 - 1
        profilePictureView.layer.borderColor = UIColor.grayColor().CGColor
        profilePictureView.layer.borderWidth = 0.5
        profilePictureView.clipsToBounds = true
            
        shadowView.addSubview(profilePictureView)
        
        let profileNameLabelHeight: CGFloat = kProfileNameLabelHeightRatio * frameHeight
        let profileNameFrame: CGRect = CGRectMake(profilePictureFrame.width, (profilePictureFrame.height - profileNameLabelHeight) / 2, frameWidth - profilePictureFrame.width, profileNameLabelHeight)
        profileNameLabel.frame = profileNameFrame.withMargin(horizontal: 5)
        profileNameLabel.adjustsFontSizeToFitWidth = true
        profileNameLabel.lineBreakMode = NSLineBreakMode.ByClipping
        profileNameLabel.font = kProfileDetailViewProfileNameLabelFont
        profileNameLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)

        let buttonFrame: CGRect = CGRectMake(profilePictureFrame.width, profileNameFrame.height + profileNameFrame.origin.y, profileNameFrame.width, frameHeight - profileNameLabelHeight - profileNameFrame.origin.y)
        recentMatchesButton.frame = buttonFrame.withMargin(horizontal: 5)
        recentMatchesButton.setTitleColor(kCouplrLinkColor, forState: .Normal)
        recentMatchesButton.setTitle("Recent matches", forState: .Normal)
        recentMatchesButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
        recentMatchesButton.contentVerticalAlignment = UIControlContentVerticalAlignment.Top
        
        bottomBorder.frame = CGRectMake(kProfileDetailViewBottomBorderWidth, frameHeight, frame.size.width - kProfileDetailViewBottomBorderWidth, kProfileDetailViewBottomBorderHeight)
        bottomBorder.backgroundColor = UIColor.grayColor().CGColor
        
        layer.addSublayer(bottomBorder)
        addSubview(profileNameLabel)
        addSubview(shadowView)
        addSubview(recentMatchesButton)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
