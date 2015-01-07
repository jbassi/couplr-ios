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
        self.graph = nil
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
                    self.tryToUpdateDirectedEdge(first, to:second, voter:voter, titleId:titleId)
                    self.tryToUpdateDirectedEdge(second, to:first, voter:voter, titleId:titleId)
                }
            }
        }
    }
    
    /**
     * Attempts to add a new match to the graph. If the match is successfully
     * added and the social graph exists, notifies the social graph about the
     * new match.
     */
    public func userDidMatch(firstId:UInt64, toSecondId:UInt64, withTitleId:Int, andRootUser:UInt64 = 0) {
        if andRootUser == 0 && graph == nil {
            log("MatchGraph::userDidMatch expected self.graph to exist. Cannot register match.", withFlag:"-")
            return
        }
        var didUpdate:Bool = tryToUpdateDirectedEdge(firstId, to:toSecondId, voter:andRootUser, titleId:withTitleId)
        didUpdate = didUpdate && tryToUpdateDirectedEdge(toSecondId, to:firstId, voter:andRootUser , titleId:withTitleId)
        if !didUpdate {
            log("User already voted on [\(firstId), \(toSecondId)] with title \"\(titles[withTitleId])\"")
            return
        }
        graph?.userDidMatch(firstId, toSecondId:toSecondId)
    }
    
    /**
     * Updates the graph going in one direction. Returns if the edge was successfully
     * added (i.e. the user did not already vote on the pair for the same title).
     */
    private func tryToUpdateDirectedEdge(from:UInt64, to:UInt64, voter:UInt64, titleId:Int) -> Bool {
        // Make a new adjacency map if none exists.
        if matches[from] == nil {
            matches[from] = [UInt64:MatchList]()
        }
        // Make a new MatchList if none exists.
        if matches[from]![to] == nil {
            matches[from]![to] = MatchList()
        }
        return matches[from]![to]!.updateMatch(titleId, voter:voter)
    }
    
    var matches:[UInt64:[UInt64:MatchList]]
    var titles:[Int:MatchTitle]
    var graph:SocialGraph?
}
