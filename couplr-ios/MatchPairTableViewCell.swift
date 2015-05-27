//
//  MatchPairTableViewCell.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 3/26/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class MatchPairTableViewCell: UITableViewCell {
    
    var leftName: String = ""
    var rightName: String = ""
    let rightTransparentLayer = UIView()
    let leftTransparentLayer = UIView()
    let leftNameLabel = UILabel()
    let rightNameLabel = UILabel()
    
    let leftCellImage = UIImageView()
    let rightCellImage = UIImageView()
    let cellText = UILabel()
    let dateLabel = UILabel()
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        let cellImageInsets: CGFloat = 10.0
        let imageSize = bounds.height - cellImageInsets * 2
        
        let rightCellX: CGFloat = frame.size.width - imageSize - cellImageInsets
        let leftCellX: CGFloat = frame.size.width - (imageSize * 2) - (cellImageInsets * 2)
        
        rightCellImage.frame = CGRectMake(rightCellX, cellImageInsets, imageSize, imageSize)
        leftCellImage.frame = CGRectMake(leftCellX, cellImageInsets, imageSize, imageSize)
        
        rightCellImage.layer.cornerRadius = 30
        rightCellImage.layer.masksToBounds = true
        leftCellImage.layer.cornerRadius = 30
        leftCellImage.layer.masksToBounds = true
        
        let cellTextHeight: CGFloat = 30.0
        let cellTextWidth: CGFloat = frame.size.width - (imageSize * 2) - (cellImageInsets * 4)
        let cellTextY: CGFloat = (frame.size.height / 2) - cellTextHeight
        cellText.frame = CGRectMake(cellImageInsets, cellTextY, cellTextWidth, cellTextHeight)
        cellText.adjustsFontSizeToFitWidth = true
        cellText.font = UIFont.systemFontOfSize(20)
        
        let dateLabelY: CGFloat = cellText.frame.origin.y + cellTextHeight
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
    
    func addTransparentLayerWithName(leftName: String, rightName: String) {
        rightTransparentLayer.frame = rightCellImage.frame
        rightTransparentLayer.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        rightTransparentLayer.layer.masksToBounds = true
        rightTransparentLayer.layer.cornerRadius = rightCellImage.layer.cornerRadius
        
        leftTransparentLayer.frame = leftCellImage.frame
        leftTransparentLayer.backgroundColor = UIColor(white: 0.1, alpha: 0.8)
        leftTransparentLayer.layer.masksToBounds = true
        leftTransparentLayer.layer.cornerRadius = leftCellImage.layer.cornerRadius
        
        leftNameLabel.numberOfLines = 0
        leftNameLabel.frame = CGRectMake(0, 0, leftTransparentLayer.frame.width, leftTransparentLayer.frame.height)
        leftNameLabel.textColor = UIColor.whiteColor()
        leftNameLabel.font = UIFont.boldSystemFontOfSize(12)
        leftNameLabel.text = leftName
        leftNameLabel.textAlignment = NSTextAlignment.Center
        
        rightNameLabel.numberOfLines = 0
        rightNameLabel.frame = CGRectMake(0, 0, rightTransparentLayer.frame.width, rightTransparentLayer.frame.height)
        rightNameLabel.textColor = UIColor.whiteColor()
        rightNameLabel.font = UIFont.boldSystemFontOfSize(12)
        rightNameLabel.text = rightName
        rightNameLabel.textAlignment = NSTextAlignment.Center
        
        leftTransparentLayer.addSubview(leftNameLabel)
        addSubview(leftTransparentLayer)
        rightTransparentLayer.addSubview(rightNameLabel)
        addSubview(rightTransparentLayer)
    }
    
    func removeTransparentLayer() {
        UIView.animateWithDuration(kProfilePictureCollectionViewCellHideAnimationDuration, animations: {
            self.leftTransparentLayer.backgroundColor = UIColor.clearColor()
            self.rightTransparentLayer.backgroundColor = UIColor.clearColor()
            self.leftNameLabel.textColor = UIColor.clearColor()
            self.rightNameLabel.textColor = UIColor.clearColor()
            }, completion: { (value: Bool) in
                self.leftTransparentLayer.removeFromSuperview()
                self.rightTransparentLayer.removeFromSuperview()
                self.leftNameLabel.removeFromSuperview()
                self.rightNameLabel.removeFromSuperview()
        })
    }
    
    func addTransparentLayer() {
        addTransparentLayerWithName(leftName, rightName: rightName)
    }

}
