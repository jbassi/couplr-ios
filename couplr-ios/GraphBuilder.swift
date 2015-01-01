//
//  GraphBuilder.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 12/30/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

/**
 * Represents a set of edges used to construct a SocialGraph.
 */
class EdgePair : Hashable {
    init(first:UInt64, second:UInt64) {
        if first > second {
            self.first = second
            self.second = first
        } else {
            self.first = first
            self.second = second
        }
    }
    
    var hashValue:Int {
        return (Int(self.first) & 0xFFFFFFFF) + (Int(self.second) & 0xFFFFFFFF << 32)
    }
    
    var first:UInt64
    var second:UInt64
}

func ==(a: EdgePair, b: EdgePair) -> Bool {
    return a.first == b.first && a.second == b.second
}

class GraphBuilder {
    init() {
        self.edges = [EdgePair:Float]()
        self.names = [UInt64:String]()
        self.rootID = 0
    }
    
    func buildSocialGraph() -> SocialGraph {
        let result:SocialGraph = SocialGraph(root:self.rootID, names:self.names)
        for (pair:EdgePair, weight:Float) in self.edges {
            result.connectNode(pair.first, toNode: pair.second, withWeight: weight)
        }
        return result
    }
    
    func updateRootUserID(id:UInt64) {
        self.rootID = id
    }
    
    func updateNameMappingForID(id:UInt64, toName:String) {
        self.names[id] = toName
    }
    
    func updateForEdgePair(pair:EdgePair, withWeight:Float) -> Bool {
        if self.names[pair.first] == nil || self.names[pair.second] == nil || pair.first >= pair.second {
            // Do not allow self-edges or edges connecting unknown ids.
            return false
        }
        if self.edges[pair] != nil {
            let newWeight:Float = self.edges[pair]! + withWeight
            if newWeight == 0 {
                // If the updated weight is zero, simply remove the edge.
                self.edges[pair] = nil
            } else {
                self.edges[pair] = newWeight
            }
        } else {
            self.edges[pair] = withWeight
        }
        return true
    }
    
    var edges:[EdgePair:Float]
    var names:[UInt64:String]
    var rootID:UInt64
}
