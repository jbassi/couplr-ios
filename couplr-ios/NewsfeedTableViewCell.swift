//
//  NewsfeedTableViewCell.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 3/26/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class NewsfeedTableViewCell: UITableViewCell {
    
    let leftCellImage = UIImageView()
    let rightCellImage = UIImageView()
    let cellText = UILabel()
    let dateLabel = UILabel()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cellImageInsets:CGFloat = 10.0
        let imageSize = bounds.height - cellImageInsets * 2
        
        let rightCellX:CGFloat = frame.size.width - imageSize - cellImageInsets
        let leftCellX:CGFloat = frame.size.width - (imageSize * 2) - (cellImageInsets * 2)
        
        rightCellImage.frame = CGRectMake(rightCellX, cellImageInsets, imageSize, imageSize)
        leftCellImage.frame = CGRectMake(leftCellX, cellImageInsets, imageSize, imageSize)
        
        rightCellImage.layer.cornerRadius = 30
        rightCellImage.layer.masksToBounds = true
        leftCellImage.layer.cornerRadius = 30
        leftCellImage.layer.masksToBounds = true
        
        let cellTextHeight:CGFloat = 30.0
        let cellTextWidth:CGFloat = frame.size.width - (imageSize * 2) - (cellImageInsets * 4)
        let cellTextY:CGFloat = (frame.size.height / 2) - cellTextHeight
        cellText.frame = CGRectMake(cellImageInsets, cellTextY, cellTextWidth, cellTextHeight)
        cellText.adjustsFontSizeToFitWidth = true
        cellText.font = UIFont.systemFontOfSize(20)
        
        let dateLabelY:CGFloat = cellText.frame.origin.y + cellTextHeight
        dateLabel.frame = CGRectMake(cellImageInsets, dateLabelY, cellTextWidth, cellTextHeight)
        dateLabel.textColor = UIColor.lightGrayColor()
    }

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        addSubview(leftCellImage)
        addSubview(rightCellImage)
        addSubview(cellText)
        addSubview(dateLabel)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
