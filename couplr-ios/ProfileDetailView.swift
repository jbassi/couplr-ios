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
    
    let profilePictureView = ProfilePictureImageView()
    let profileNameLabel = UILabel()
    let recentMatchesButton = UIButton()
    let bottomBorder = CALayer()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        let frameWidth = frame.size.width
        let frameHeight = frame.size.height
        
        let profilePictureMask = UIView(frame: CGRectMake(frameWidth * kProfileDetailViewProfilePictureXRatio, frameHeight * kProfileDetailViewProfilePictureYRatio, frameHeight * kProfileDetailViewProfilePictureRatio, frameHeight * kProfileDetailViewProfilePictureRatio))
        let profilePictureCircle = UIView(frame: CGRectMake(profilePictureMask.frame.origin.x - kProfileDetailViewProfilePicturePadding, profilePictureMask.frame.origin.y - kProfileDetailViewProfilePicturePadding, profilePictureMask.frame.size.width + 2 * kProfileDetailViewProfilePicturePadding, profilePictureMask.frame.size.height + 2 * kProfileDetailViewProfilePicturePadding))
        profilePictureCircle.backgroundColor = UIColor.grayColor()
        profilePictureCircle.layer.cornerRadius = profilePictureCircle.frame.size.height / 2
        profilePictureMask.layer.cornerRadius = profilePictureMask.frame.size.height / 2
        
        profilePictureView.frame = CGRectMake(0, 0, profilePictureMask.frame.size.width, profilePictureMask.frame.size.height)
        profilePictureMask.addSubview(profilePictureView)
        profilePictureMask.clipsToBounds = true
        
        let profileNameLabelX: CGFloat = profilePictureCircle.frame.origin.x + profilePictureCircle.frame.size.width + 10
        let profileNameLabelY: CGFloat = profilePictureCircle.frame.origin.y + (profilePictureCircle.frame.size.height / 2) - (kProfileDetailViewNameLabelX / 2)
        profileNameLabel.frame = CGRectMake(profileNameLabelX, profileNameLabelY, frame.size.width - profileNameLabelX - kProfileDetailViewBottomBorderWidth - 10, kProfileDetailViewNameLabelX)
        profileNameLabel.adjustsFontSizeToFitWidth = true
        profileNameLabel.lineBreakMode = NSLineBreakMode.ByClipping
        profileNameLabel.font = kProfileDetailViewProfileNameLabelFont
        profileNameLabel.textColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.8)
        
        bottomBorder.frame = CGRectMake(kProfileDetailViewBottomBorderWidth, frame.origin.y + frame.size.height, frame.size.width - kProfileDetailViewBottomBorderWidth, kProfileDetailViewBottomBorderHeight)
        bottomBorder.backgroundColor = UIColor.grayColor().CGColor
        
        recentMatchesButton.frame = CGRectMake(profileNameLabelX, profileNameLabelY + profileNameLabel.frame.height + 5, 150, 40)
        recentMatchesButton.backgroundColor = UIColor.lightGrayColor()
        recentMatchesButton.setTitle("Recent Matches", forState: .Normal)
        recentMatchesButton.layer.cornerRadius = 20
        recentMatchesButton.layer.masksToBounds = true
        
        self.layer.addSublayer(bottomBorder)
        self.addSubview(profileNameLabel)
        self.addSubview(profilePictureCircle)
        self.addSubview(profilePictureMask)
        self.addSubview(recentMatchesButton)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
