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
    
    /**
     * Returns a dictionary mapping each title id in this list of
     * matches to the corresponding number of votes for that title.
     */
    public func numVotesByTitleId() -> [Int:Int] {
        var result:[Int:Int] = [Int:Int]()
        for (titleId:Int, voterList:[UInt64]) in matchesByTitle {
            result[titleId] = voterList.count
        }
        return result
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
        self.fetchedIdHistory = [UInt64]()
    }
    
    /**
     * Loads match titles from Parse and passes them to a given callback
     * function.
     */
    public func fetchMatchTitles() {
        log("Requesting match titles...", withFlag:"!")
        var query = PFQuery(className:"MatchTitle")
        query.findObjectsInBackgroundWithBlock {
            (objects:[AnyObject]!, error:NSError?) -> Void in
            for title:AnyObject in objects {
                let titleId:Int = title["titleId"]! as Int
                let text:String = title["text"]! as String
                let picture:String = title["picture"]! as String
                self.titles[titleId] = MatchTitle(id:titleId, text:text, picture:picture)
            }
            log("Received \(objects.count) titles.", withIndent:1)
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
     * For a given user, a dictionary that contains, as keys, all other users
     * to which the given user has been matched. The value corresponding to
     * each key (the other user) is another dictionary mapping title id to
     * the number of votes for that title.
     *
     * For example, suppose we call matchesForUserId(A) and receive
     * [B:[3:1, 0:4]]. Then A has matches only with B, consisting of 1 vote
     * for the title with ID 3 and 4 votes for the title with ID 0.
     *
     * This queries the current state of the graph, and does not assume that
     * the matches were previously loaded for the given userId. In order to
     * ensure that matches for the userId were loaded, use a callback with
     * MatchGraph::fetchMatchesForId.
     */
    public func numMatchesByTitleForUserId(userId:UInt64) -> [UInt64:[Int:Int]] {
        var result:[UInt64:[Int:Int]] = [UInt64:[Int:Int]]()
        if matches[userId] != nil {
            for (matchedUser:UInt64, matchList:MatchList) in matches[userId]! {
                result[matchedUser] = matchList.numVotesByTitleId()
            }
        }
        return result
    }
    
    /**
     * Loads all matches relevant to a given user id. Takes an optional callback
     * function that is called when the results are received. In the case that the
     * id has already been fetched, immediately invokes the callback and returns.
     * Otherwise, invokes the callback after the response arrives and the graph update
     * finishes. The callback takes a Bool parameter indicating whether or not an
     * error occurred when receiving the data.
     */
    public func fetchMatchesForId(userId:UInt64, callback:((didError:Bool)->Void)? = nil) {
        log("Requesting match records for user \(userId)", withFlag:"!")
        // Do not re-fetch matches.
        if find(fetchedIdHistory, userId) != nil {
            log("Matches for user \(userId) already loaded.", withIndent:1)
            if callback != nil {
                callback!(didError:false)
            }
            return
        }
        let predicate:NSPredicate = NSPredicate(format:"firstId = \(userId) OR secondId = \(userId)")!
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
                // Consider a match fetched only after the response arrives.
                self.fetchedIdHistory.append(userId)
                log("Received and updated matches for user \(userId).", withIndent:1)
                if callback != nil {
                    callback!(didError:false)
                }
            } else {
                log("Error \(error!.description) occurred when loading \(userId)'s matches.", withIndent:1, withFlag:"-")
                if callback != nil {
                    callback!(didError:true)
                }
            }
        }
    }
    
    /**
     * Attempts to add a new match to the graph. If the match is successfully
     * added and the social graph exists, notifies the social graph about the
     * new match.
     */
    public func userDidMatch(firstId:UInt64, toSecondId:UInt64, withTitleId:Int, andRootUser:UInt64) {
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
    var fetchedIdHistory:[UInt64]
}
