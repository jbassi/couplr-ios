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
        
        
        
    }
   
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
