//
//  MatchGraph.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 1/4/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import Parse
import UIKit

public class MatchTitle {
    public init(id:Int, text:String, picture:String) {
        self.id = id
        self.text = text
        self.picture = picture
    }
    
    var id:Int
    var text:String
    var picture:String
}

/**
 * Represents an edge in the MatchGraph consisting of all the matches
 * between two people in the graph.
 */
public class MatchList {
    public init() {
        self.matchesByTitle = [Int:[UInt64]]()
    }
    
    /**
     * Adds a new match between two users. Returns true if the match
     * has been correctly added, otherwise returns false (e.g. if
     * the result already exists).
     */
    public func updateMatch(id:Int, voter:UInt64) -> Bool {
        if matchesByTitle[id] == nil {
            matchesByTitle[id] = []
        }
        let voterList:[UInt64] = matchesByTitle[id]!
        if find(voterList, voter) == nil {
            matchesByTitle[id]!.append(voter)
            return true
        }
        return false
    }
    
    // Maps a title ID to a list of users who voted for that match.
    var matchesByTitle:[Int:[UInt64]]
}

/**
 * Stores matches relevant to the social network as a graph.
 */
public class MatchGraph {
    public init() {
        self.matches = [UInt64:[UInt64:MatchList]]()
        self.titles = [Int:MatchTitle]()
    }
    
    /**
     * Loads match titles from Parse and passes them to a given callback
     * function.
     */
    public func fetchMatchTitles() {
        var query = PFQuery(className:"MatchTitle")
        query.findObjectsInBackgroundWithBlock {
            (objects:[AnyObject]!, error:NSError?) -> Void in
            for title:AnyObject in objects {
                let titleId:Int = title["titleId"]! as Int
                let text:String = title["text"]! as String
                let picture:String = title["picture"]! as String
                self.titles[titleId] = MatchTitle(id:titleId, text:text, picture:picture)
            }
        }
    }
    
    /**
     * Returns a string representation of this MatchGraph for (mainly) debugging
     * purposes.
     */
    public func toString() -> String {
        var result:String = "MatchGraph({\n"
        for (node:UInt64, neighbors:[UInt64:MatchList]) in matches {
            result += "    \(node)'s matches:\n"
            for (neighbor:UInt64, matchList:MatchList) in neighbors {
                for (titleId:Int, voters:[UInt64]) in matchList.matchesByTitle {
                    result += "        with \(neighbor) (\(voters.count) votes): \(titles[titleId]!.text)\n"
                }
            }
            result += "\n"
        }
        return result + "})\n"
    }
    
    /**
     * Loads all matches relevant to a given user id.
     */
    public func fetchMatchesForId(id:UInt64) {
        let predicate:NSPredicate = NSPredicate(format:"firstId = \(id) OR secondId = \(id)")!
        var query = PFQuery(className:"MatchData", predicate:predicate)
        query.findObjectsInBackgroundWithBlock {
            (objects:[AnyObject]!, error:NSError?) -> Void in
            if error == nil {
                for index in 0..<objects.count {
                    let matchData:AnyObject! = objects[index]
                    let first:UInt64 = uint64FromAnyObject(matchData["firstId"])
                    let second:UInt64 = uint64FromAnyObject(matchData["secondId"])
                    let voter:UInt64 = uint64FromAnyObject(matchData["voterId"])
                    let titleId:Int = matchData["titleId"] as Int
                    self.updateDirectedEdge(first, to:second, voter:voter, titleId:titleId)
                    self.updateDirectedEdge(second, to:first, voter:voter, titleId:titleId)
                }
            }
        }
    }
    
    /**
     * Updates the graph going in one direction.
     */
    private func updateDirectedEdge(from:UInt64, to:UInt64, voter:UInt64, titleId:Int) {
        // Make a new adjacency map if none exists.
        if matches[from] == nil {
            self.matches[from] = [UInt64:MatchList]()
        }
        // Make a new MatchList if none exists.
        if self.matches[from]![to] == nil {
            self.matches[from]![to] = MatchList()
        }
        self.matches[from]![to]!.updateMatch(titleId, voter:voter)
    }
    
    var matches:[UInt64:[UInt64:MatchList]]
    var titles:[Int:MatchTitle]
}
