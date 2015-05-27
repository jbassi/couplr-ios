//
//  ImageTitleTableViewCell.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 3/25/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class ImageTitleTableViewCell: ImageTableViewCell {
    
    let cellSubText = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(cellSubText)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        cellText.frame.origin.y = 10
        let cellSubTextY: CGFloat = cellText.frame.height + 5
        cellSubText.frame = CGRectMake(cellText.frame.origin.x, cellSubTextY, cellText.frame.width, cellText.frame.height)
        cellSubText.textColor = UIColor.lightGrayColor()
    }
   
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
