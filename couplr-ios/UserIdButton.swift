//
//  UserIdButton.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 6/1/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

/**
 * TODO I tried to make this a generic DataButton<T>, but the Swift compiler throws a
 * segfault when I try to compile! This is a temporary workaround.
 */
class UserIdButton: UIButton {
    
    var userId: UInt64 = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func setId(userId: UInt64) {
        self.userId = userId
    }
}
