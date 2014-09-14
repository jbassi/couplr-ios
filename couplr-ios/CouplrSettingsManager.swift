//
//  CouplrSettingsManager.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 9/13/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class CouplrSettingsManager: NSObject {
    // TODO: Make static?
    let kShouldSkipLoginKey: String = "kShouldSkipLoginKey"
    
    class var sharedInstance: CouplrSettingsManager {
        struct CouplrSingleton {
            static let instance = CouplrSettingsManager()
        }
        return CouplrSingleton.instance
    }
    
    var shouldSkipLogin: Bool {
        get {
            return NSUserDefaults.standardUserDefaults().boolForKey(kShouldSkipLoginKey)
        }
        set (value) {
            let defaults: NSUserDefaults = NSUserDefaults.standardUserDefaults()
            defaults.setBool(value, forKey: kShouldSkipLoginKey)
            defaults.synchronize()
        }
    }
}
