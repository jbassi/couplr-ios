//
//  ImageActionTableViewCell.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 6/1/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class ImageActionTableViewCell: ImageTableViewCell {
    
    let actionButton: UserIdButton = UserIdButton()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(actionButton)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        cellText.frame.origin.y = 10
        let cellSubTextY: CGFloat = cellText.frame.height + 5
        actionButton.frame = CGRectMake(cellText.frame.origin.x, cellSubTextY, 100, cellText.frame.height)
        actionButton.setTitle("View profile", forState: .Normal)
        actionButton.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 15)
        actionButton.setTitleColor(kCouplrLinkColor, forState: .Normal)
        actionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignment.Left
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

