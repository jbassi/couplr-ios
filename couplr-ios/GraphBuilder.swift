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
        return (Int(self.first) & 0xFFFFFFFF) + (Int(self.second) & 0xFFFFFFFF << 32)
    }
    
    var first:UInt64
    var second:UInt64
}

public func ==(a: EdgePair, b: EdgePair) -> Bool {
    return a.first == b.first && a.second == b.second
}

public class GraphBuilder {
    init(forRootUserID:UInt64, withName:String) {
        self.edges = [EdgePair:Float]()
        self.names = [forRootUserID:withName]
        self.rootID = forRootUserID
        self.commentsWithLikesForAuthor = [String:UInt64]()
    }
    
    public func buildSocialGraph(andLoadGender:Bool = true, andFetchCommentLikes:Bool = true) -> SocialGraph {
        let graph:SocialGraph = SocialGraph(root:self.rootID, names:self.names)
        for (pair:EdgePair, weight:Float) in self.edges {
            graph.connectNode(pair.first, toNode: pair.second, withWeight: weight)
        }
        if andLoadGender {
            graph.updateGenders()
        }
        if andFetchCommentLikes {
            graph.updateCommentLikes(commentsWithLikesForAuthor)
        }
        return graph
    }
    
    public func updateRootUserID(id:UInt64) {
        self.rootID = id
    }
    
    public func updateNameMappingForID(id:UInt64, toName:String) {
        self.names[id] = toName
    }
    
    public func updateForEdgePair(pair:EdgePair, withWeight:Float) -> Bool {
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
    
    public func updateCommentsWithLikes(id:String, forAuthorID:UInt64) {
        commentsWithLikesForAuthor[id] = forAuthorID
    }
    
    var edges:[EdgePair:Float]
    var names:[UInt64:String]
    var rootID:UInt64
    var commentsWithLikesForAuthor:[String:UInt64]
}
