//
//  ProfileViewControllerTableViewCell.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 1/6/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class ProfileViewControllerTableViewCell: UITableViewCell {

    let numberOfTimesVotedLabel = UILabel()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        self.addSubview(numberOfTimesVotedLabel)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        textLabel?.frame.size.width -= (kProfileViewControllerTableViewCellWidth - kProfileViewControllerTableViewCellPadding)
        
        numberOfTimesVotedLabel.frame = CGRectMake(bounds.size.width-kProfileViewControllerTableViewCellWidth-kProfileViewControllerTableViewCellPadding, 0, kProfileViewControllerTableViewCellWidth, bounds.size.height)
        numberOfTimesVotedLabel.textAlignment = NSTextAlignment.Center
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
