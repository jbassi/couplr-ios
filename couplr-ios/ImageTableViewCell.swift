//
//  ImageTableViewCell.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 3/25/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class ImageTableViewCell: UITableViewCell {
    
    let numberOfTimesVotedLabel = UILabel()
    let cellImage = UIImageView()
    let cellText = UILabel()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(numberOfTimesVotedLabel)
        addSubview(cellImage)
        addSubview(cellText)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cellImageInsets: CGFloat = 10.0
        cellImage.frame = CGRectMake(cellImageInsets, cellImageInsets, bounds.height - cellImageInsets * 2, bounds.height - cellImageInsets * 2)
        
        numberOfTimesVotedLabel.frame = CGRectMake(bounds.size.width-kImageTableViewCellWidth, 0, kImageTableViewCellWidth, bounds.size.height)
        numberOfTimesVotedLabel.textAlignment = NSTextAlignment.Center
        
        let cellTextWidth = bounds.width - (cellImage.frame.origin.x+cellImage.frame.width+10) - (numberOfTimesVotedLabel.frame.width)
        let cellHeight: CGFloat = 30.0
        let cellX: CGFloat = cellImage.frame.origin.x+cellImage.frame.width+20
        let cellY: CGFloat = (bounds.size.height / 2) - (cellHeight / 2)
        cellText.frame = CGRectMake(cellX, cellY, cellTextWidth, cellHeight)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
