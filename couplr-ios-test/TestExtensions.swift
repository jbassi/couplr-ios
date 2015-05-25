//
//  TestExtensions.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 5/25/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

extension MatchGraphController {
    public class func get() -> MatchGraphController {
        return MatchGraphController.sharedInstance
    }
    
    public func setMatchGraph(matches: MatchGraph) {
        self.matches = matches
    }
}

extension SocialGraphController {
    public func setSocialGraph(graph: SocialGraph) {
        self.graph = graph
    }
    
    public class func get() -> SocialGraphController {
        return SocialGraphController.sharedInstance
    }
}

extension MatchGraph {
    public func setDidFetchUserMatchHistory(didFetchUserMatchHistory: Bool) {
        self.didFetchUserMatchHistory = didFetchUserMatchHistory
    }
}
