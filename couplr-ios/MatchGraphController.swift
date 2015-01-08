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
        if matches == nil {
            matches = MatchGraph()
        }
        matches?.fetchMatchTitles()
    }
    
    func socialGraphDidLoad() {
        if matches == nil {
            matches = MatchGraph()
        }
        matches!.graph = SocialGraphController.sharedInstance.graph
        matches!.fetchMatchesForId(matches!.graph!.root)
        matches!.fetchRootUserMatchHistory()
    }
    
    /**
     * Notifies the MatchGraph that the root user performed a match.
     * Will assume that the SocialGraph has already been initialized,
     * so the root user is graph!.root.
     */
    func userDidMatch(firstId:UInt64, toSecondId:UInt64, withTitleId:Int) {
        matches?.userDidMatch(firstId, toSecondId:toSecondId, withTitleId:withTitleId)
    }
}