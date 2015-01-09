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
        self.titlesById = [Int:MatchTitle]()
        self.titleList = [MatchTitle]()
        self.fetchedIdHistory = [UInt64]()
        self.didFetchUserMatchHistory = false
        self.currentlyFlushingMatches = false
        self.unregisteredMatches = [(UInt64, UInt64, Int)]()
        self.matchesBeforeUserHistoryLoaded = [(UInt64, UInt64, Int)]()
    }
    
    /**
     * Loads match titles from Parse and passes them to a given callback
     * function.
     */
    public func fetchMatchTitles(callback:((didError:Bool)->Void)? = nil) {
        log("Requesting match titles...", withFlag:"!")
        var query = PFQuery(className:"MatchTitle")
        query.findObjectsInBackgroundWithBlock {
            (objects:[AnyObject]!, error:NSError?) -> Void in
            if error == nil {
                for title:AnyObject in objects {
                    let titleId:Int = title["titleId"]! as Int
                    let text:String = title["text"]! as String
                    let picture:String = title["picture"]! as String
                    self.titlesById[titleId] = MatchTitle(id:titleId, text:text, picture:picture)
                }
                for title:MatchTitle in self.titlesById.values {
                    self.titleList.append(title)
                }
                self.titleList = sorted(self.titleList, {(first:MatchTitle, second:MatchTitle) -> Bool in
                    return first.id < second.id
                })
                log("Received \(objects.count) titles.", withIndent:1)
                if callback != nil {
                    callback!(didError:false)
                }
            } else {
                log("Error \"\(error!.description)\" while retrieving titles.", withIndent:1, withFlag:"-")
                if callback != nil {
                    callback!(didError:true)
                }
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
                    result += "        with \(neighbor) (\(voters.count) votes): \(titlesById[titleId]!.text)\n"
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
     * For example, suppose we call numMatchesByUserIdAndTitleFor(A) and
     * receive [B:[3:1, 0:4]]. Then A has matches only with B, consisting
     * of 1 vote for the title with ID 3 and 4 votes for the title with ID 0.
     *
     * This queries the current state of the graph, and does not assume that
     * the matches were previously loaded for the given userId. In order to
     * ensure that matches for the userId were loaded, use a callback with
     * MatchGraph::fetchMatchesForId.
     */
    public func numMatchesByUserIdAndTitleFor(userId:UInt64) -> [UInt64:[Int:Int]] {
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
            if callback != nil {
                callback!(didError:false)
            }
            return log("Matches for user \(userId) already loaded.", withIndent:1)
        }
        let predicate:NSPredicate = NSPredicate(format:"firstId = \"\(userId)\" OR secondId = \"\(userId)\"")!
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
                log("Received and updated \(objects.count) matches for user \(userId).", withIndent:1)
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
     * Queries Parse for the matches the user has voted on, updating the graph
     * correspondingly, and running a given callback function upon receiving a
     * response.
     */
    public func fetchRootUserVoteHistory(callback:((didError:Bool) -> Void)? = nil) {
        let rootUser:UInt64 = rootUserFromGraph()
        if rootUser == 0 {
            return log("Warning: MatchGraph::fetchRootUserMatchHistory called before social graph was initialized.", withFlag:"-")
        }
        if didFetchUserMatchHistory {
            return log("Request for user history denied. Already fetched root user history.", withFlag:"?")
        }
        log("Requesting match history for current user.", withFlag:"!")
        let predicate:NSPredicate = NSPredicate(format:"voterId = \"\(rootUser)\"")!
        var query = PFQuery(className:"MatchData", predicate:predicate)
        query.findObjectsInBackgroundWithBlock {
            (objects:[AnyObject]!, error:NSError?) -> Void in
            if error == nil {
                for index:Int in 0..<objects.count {
                    let matchData:AnyObject! = objects[index]
                    let first:UInt64 = uint64FromAnyObject(matchData["firstId"])
                    let second:UInt64 = uint64FromAnyObject(matchData["secondId"])
                    let titleId:Int = matchData["titleId"] as Int
                    self.tryToUpdateDirectedEdge(first, to:second, voter:rootUser, titleId:titleId)
                    self.tryToUpdateDirectedEdge(second, to:first, voter:rootUser, titleId:titleId)
                }
                self.didFetchUserMatchHistory = true
                self.checkMatchesBeforeUserHistoryLoaded()
                log("User voted on \(objects.count) matches.", withIndent:1)
                if callback != nil {
                    callback!(didError:false)
                }
            } else {
                log("Error \"\(error!.description)\" while fetching user match history.", withIndent:1, withFlag:"-")
                if callback != nil {
                    callback!(didError:true)
                }
            }
        }
    }
    
    /**
     * Saves all unregistered matches to Parse. Should be invoked when the app
     * is about to close, but can also be invoked periodically to prevent matches
     * from disappearing in the case of a crash.
     */
    public func flushUnregisteredMatches() {
        let rootUser:UInt64 = rootUserFromGraph()
        if rootUser == 0 {
            return log("Warning: MatchGraph::flushUnregisteredMatches called before social graph was initialized.", withFlag:"-")
        }
        if currentlyFlushingMatches {
            return log("Warning: already attempting to flush unregistered matches.", withFlag:"-")
        }
        currentlyFlushingMatches = true
        log("Saving \(unregisteredMatches.count) matches to Parse...")
        var newMatches:[PFObject] = [PFObject]()
        for (firstId:UInt64, secondId:UInt64, titleId:Int) in unregisteredMatches {
            var newMatch:PFObject = PFObject(className:"MatchData")
            newMatch["firstId"] = firstId.description
            newMatch["secondId"] = secondId.description
            newMatch["voterId"] = rootUser.description
            newMatch["titleId"] = titleId
            newMatches.append(newMatch)
        }
        PFObject.saveAll(newMatches)
        log("Successfully saved \(self.unregisteredMatches.count) matches to Parse.", withIndent:1)
    }
    
    /**
     * Attempts to add a new match to the graph. If the match is successfully
     * added and the social graph exists, notifies the social graph about the
     * new match.
     */
    public func userDidMatch(firstId:UInt64, toSecondId:UInt64, withTitleId:Int) {
        if firstId == toSecondId {
            return log("User voted \(firstId) with him/herself!", withFlag:"-")
        }
        if !didFetchUserMatchHistory {
            if firstId < toSecondId {
                matchesBeforeUserHistoryLoaded.append((firstId, toSecondId, withTitleId))
            } else {
                matchesBeforeUserHistoryLoaded.append((toSecondId, firstId, withTitleId))
            }
            return
        }
        let rootUser:UInt64 = rootUserFromGraph()
        if rootUser == 0 {
            return log("Warning: MatchGraph::userDidMatch called before social graph was initialized.", withFlag:"-")
        }
        var didUpdate:Bool = tryToUpdateDirectedEdge(firstId, to:toSecondId, voter:rootUser, titleId:withTitleId)
        didUpdate = didUpdate && tryToUpdateDirectedEdge(toSecondId, to:firstId, voter:rootUser , titleId:withTitleId)
        if !didUpdate {
            return log("User already voted on [\(firstId), \(toSecondId)] with title \"\(titlesById[withTitleId]!.text)\"")
        }
        if firstId < toSecondId {
            unregisteredMatches.append((firstId, toSecondId, withTitleId))
        } else {
            unregisteredMatches.append((toSecondId, firstId, withTitleId))
        }
        SocialGraphController.sharedInstance.userDidMatch(firstId, toSecondId:toSecondId)
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
    
    /**
     * Grabs the root user ID from the graph. If the graph has not been loaded, returns
     * a default error value of 0.
     */
    private func rootUserFromGraph() -> UInt64 {
        if SocialGraphController.sharedInstance.graph == nil {
            return 0
        }
        return SocialGraphController.sharedInstance.rootId()
    }
    
    /**
     * Walks through the list of user-supplied matches before the user's match history
     * was loaded and appends valid matches (i.e. those the user has not already voted
     * on) to the list of registered matches.
     *
     * This allows users to supply matches before the response containing the user's match
     * history arrives.
     */
    private func checkMatchesBeforeUserHistoryLoaded() {
        let rootUser:UInt64 = rootUserFromGraph()
        if rootUser == 0 {
            return log("Warning: MatchGraph::checkMatchesBeforeUserHistoryLoaded called before social graph was initialized.", withFlag:"-")
        }
        for (firstId:UInt64, secondId:UInt64, titleId:Int) in matchesBeforeUserHistoryLoaded {
            var didUpdate:Bool = tryToUpdateDirectedEdge(firstId, to:secondId, voter:rootUser, titleId:titleId)
            didUpdate = didUpdate && tryToUpdateDirectedEdge(secondId, to:firstId, voter:rootUser , titleId:titleId)
            if !didUpdate {
                return log("User already voted on [\(firstId), \(secondId)] with title \"\(titlesById[titleId]!.text)\"")
            }
            log("Appending buffered match [\(firstId), \(secondId)] with title \"\(titlesById[titleId])\" to unregistered matches.")
            unregisteredMatches.append((firstId, secondId, titleId))
        }
        matchesBeforeUserHistoryLoaded.removeAll()
    }
    
    var matches:[UInt64:[UInt64:MatchList]]
    var titlesById:[Int:MatchTitle]
    var titleList:[MatchTitle]
    var fetchedIdHistory:[UInt64]
    var didFetchUserMatchHistory:Bool
    var currentlyFlushingMatches:Bool
    var unregisteredMatches:[(UInt64, UInt64, Int)]
    var matchesBeforeUserHistoryLoaded:[(UInt64, UInt64, Int)]
}
