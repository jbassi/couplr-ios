//
//  MatchGraphController.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 1/6/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

public class MatchGraphController {

    var matches: MatchGraph?
    
    class var sharedInstance: MatchGraphController {
        struct MatchGraphSingleton {
            static let instance = MatchGraphController()
        }
        return MatchGraphSingleton.instance
    }
    
    func appDidLoad() {
        matches = MatchGraph()
        matches?.fetchMatchTitles()
    }
    
    func socialGraphDidInitialize() {
        matches?.graph = SocialGraphController.sharedInstance.graph
    }
    
    func userDidMatch(firstId:UInt64, toSecondId:UInt64, withTitleId:Int, var andRootUser:UInt64 = 0) {
        if andRootUser == 0 {
            if SocialGraphController.sharedInstance.graph == nil {
                log("MatchGraphController::userDidMatch expected a valid root user.", withFlag:"-")
                return
            }
            andRootUser = SocialGraphController.sharedInstance.graph!.root
        }
        matches?.userDidMatch(firstId, toSecondId:toSecondId, withTitleId:withTitleId, andRootUser:andRootUser)
    }
}