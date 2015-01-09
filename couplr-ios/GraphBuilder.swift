//
//  GraphBuilder.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 12/30/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

/**
 * Represents a set of edges used to construct a SocialGraph. Forms the glue between
 * the graph data structure and the parsed comment data from Facebook.
 */
public class EdgePair : Hashable {
    init(first:UInt64, second:UInt64) {
        if first > second {
            self.first = second
            self.second = first
        } else {
            self.first = first
            self.second = second
        }
    }
    
    public var hashValue:Int {
        let sum:UInt64 = first + second
        return (UInt(sum & 0xFFFF0000) ^ UInt(sum & 0x0000FFFF)).hashValue
    }
    
    var first:UInt64
    var second:UInt64
}

public func ==(a: EdgePair, b: EdgePair) -> Bool {
    return a.first == b.first && a.second == b.second
}

public class GraphBuilder {
    init(forRootUserId:UInt64, withName:String) {
        self.edges = [EdgePair:Float]()
        self.names = [forRootUserId:withName]
        self.rootId = forRootUserId
    }
    
    public func buildSocialGraph() -> SocialGraph {
        let graph:SocialGraph = SocialGraph(root:self.rootId, names:self.names)
        for (pair:EdgePair, weight:Float) in self.edges {
            graph.connectNode(pair.first, toNode: pair.second, withWeight: weight)
        }
        return graph
    }
    
    public func updateRootUserID(id:UInt64) {
        self.rootId = id
    }
    
    public func updateNameMappingForId(id:UInt64, toName:String) {
        self.names[id] = toName
    }
    
    public func updateForEdgePair(pair:EdgePair, withWeight:Float) -> Bool {
        if self.names[pair.first] == nil || self.names[pair.second] == nil || pair.first >= pair.second {
            // Do not allow self-edges or edges connecting unknown ids.
            return false
        }
        if self.edges[pair] != nil {
            let newWeight:Float = self.edges[pair]! + withWeight
            if abs(newWeight) < 0.01 {
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
    var rootId:UInt64
}
