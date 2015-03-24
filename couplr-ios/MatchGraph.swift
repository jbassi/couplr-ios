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
 * Represents a tuple uniquely identifying a voter who matched two users
 * for some title. Includes the IDs of the two people who were matched,
 * the ID of the voter, and the title id.
 */
public class MatchTuple : Hashable {
    public init(firstId:UInt64, secondId:UInt64, voterId:UInt64, titleId:Int) {
        if firstId > secondId {
            self.firstId = secondId
            self.secondId = firstId
        } else {
            self.firstId = firstId
            self.secondId = secondId
        }
        self.voterId = voterId
        self.titleId = titleId
    }
    
    public var hashValue:Int {
//        return Int(self.firstId + self.secondId + self.titleId + self.voterId)
        return 0
    }
    
    var firstId:UInt64
    var secondId:UInt64
    var voterId:UInt64
    var titleId:Int
}

public func ==(lhs:MatchTuple, rhs:MatchTuple) -> Bool {
    return lhs.firstId == rhs.firstId && lhs.secondId == rhs.secondId && lhs.voterId == rhs.voterId && lhs.titleId == rhs.titleId
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
        self.titlesById = [Int:MatchTitle]()
        self.titleList = [MatchTitle]()
        self.fetchedIdHistory = [UInt64]()
        self.didFetchUserMatchHistory = false
        self.currentlyFlushingMatches = false
        self.unregisteredMatches = [(UInt64, UInt64, Int)]()
        self.matchesBeforeUserHistoryLoaded = [(UInt64, UInt64, Int)]()
        self.userVoteHistory = [(UInt64, UInt64, Int)]()
        self.cachedMatchesByTitle = [UInt64:[(Int,[(UInt64,Int)])]]()
        self.matchUpdateTimes = [MatchTuple:NSDate]()
    }

    /**
     * Loads match titles from Parse and passes them to a given callback
     * function.
     */
    public func fetchMatchTitles(callback:((didError:Bool)->Void)? = nil) {
        log("Requesting match titles...", withFlag: "!")
        var query = PFQuery(className: "MatchTitle")
        query.findObjectsInBackgroundWithBlock {
            (objects:[AnyObject]!, error:NSError?) -> Void in
            if error == nil {
                for title:AnyObject in objects {
                    let titleId:Int = title["titleId"]! as Int
                    let text:String = title["text"]! as String
                    let picture:String = title["picture"]! as String
                    self.titlesById[titleId] = MatchTitle(id: titleId, text: text, picture: picture)
                }
                for title:MatchTitle in self.titlesById.values {
                    self.titleList.append(title)
                }
                self.titleList = sorted(self.titleList, {(first: MatchTitle, second: MatchTitle) -> Bool in
                    return first.id < second.id
                })
                log("Received \(objects.count) titles.", withIndent: 1, withNewline: true)
                if callback != nil {
                    callback!(didError:false)
                }
            } else {
                log("Error \"\(error!.description)\" while retrieving titles.", withIndent: 1, withFlag: "-", withNewline: true)
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
     * For a given user, returns a list of (titleId, <list>) pairs, where <list> is
     * another list of (userId, vote count) pairs. This inner list is sorted by vote
     * count, and the outer list is sorted by the sum of all vote counts for the
     * titleId.
     *
     * This list of sorted matches will not include neighbors that the root user does
     * not know about (i.e. users who do not appear in the root user's social graph).
     */
    public func sortedMatchesForUser(userId:UInt64) -> [(Int,[(UInt64,Int)])] {
        if cachedMatchesByTitle[userId] != nil {
            return cachedMatchesByTitle[userId]!
        }
        if matches[userId] == nil {
            return [(Int,[(UInt64,Int)])]()
        }
        var matchResultSet:[Int:[UInt64:Int]] = [Int:[UInt64:Int]]()
        var matchCountsByTitle:[Int:Int] = [Int:Int]()
        for (neighbor:UInt64, list:MatchList) in matches[userId]! {
            // HACK Find a better way of preventing unknown users from showing up in matches.
            if !SocialGraphController.sharedInstance.containsUser(neighbor) {
                continue
            }
            for (titleId:Int, voters:[UInt64]) in list.matchesByTitle {
                if matchResultSet[titleId] == nil {
                    matchResultSet[titleId] = [UInt64:Int]()
                }
                matchResultSet[titleId]![neighbor] = voters.count
                if matchCountsByTitle[titleId] == nil {
                    matchCountsByTitle[titleId] = 0
                }
                matchCountsByTitle[titleId] = matchCountsByTitle[titleId]! + voters.count
            }
        }
        var sortedMatches:[(Int,[(UInt64,Int)])] = [(Int,[(UInt64,Int)])]()
        for (titleId:Int, results:[UInt64:Int]) in matchResultSet {
            var list:[(UInt64,Int)] = [(UInt64,Int)]()
            for (neighbor:UInt64, count:Int) in results {
                list.append((neighbor, count))
            }
            list.sort {
                (first:(UInt64,Int), second:(UInt64,Int)) -> Bool in
                return first.1 > second.1
            }
            let element:(Int,[(UInt64,Int)]) = (titleId, list)
            // TODO Why doesn't this work without using temp variable?
            sortedMatches.append(element)
        }
        sortedMatches.sort {
            (first:(Int,[(UInt64,Int)]), second:(Int,[(UInt64,Int)])) -> Bool in
            return matchCountsByTitle[first.0]! > matchCountsByTitle[second.0]!
        }
        cachedMatchesByTitle[userId] = sortedMatches
        return sortedMatches
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
            return log("Matches for user \(userId) already loaded.", withIndent:1, withNewline:true)
        }
        let predicate:NSPredicate = NSPredicate(format:"firstId = \"\(encodeBase64(userId))\" OR secondId = \"\(encodeBase64(userId))\"")!
        var query = PFQuery(className:"MatchData", predicate:predicate)
        query.findObjectsInBackgroundWithBlock {
            (objects:[AnyObject]!, error:NSError?) -> Void in
            if error == nil {
                for index in 0..<objects.count {
                    let matchData:AnyObject! = objects[index]
                    let first:UInt64 = uint64FromAnyObject(matchData["firstId"], base64:true)
                    let second:UInt64 = uint64FromAnyObject(matchData["secondId"], base64:true)
                    let voter:UInt64 = uint64FromAnyObject(matchData["voterId"], base64:true)
                    let titleId:Int = matchData["titleId"] as Int
                    self.tryToUpdateDirectedEdge(first, to:second, voter:voter, titleId:titleId)
                    self.tryToUpdateDirectedEdge(second, to:first, voter:voter, titleId:titleId)
                    let matchTuple:MatchTuple = MatchTuple(firstId:first, secondId:second, voterId:voter, titleId:titleId)
                    self.matchUpdateTimes[matchTuple] = matchData.updatedAt
                }
                // Consider a match fetched only after the response arrives.
                self.fetchedIdHistory.append(userId)
                log("Received and updated \(objects.count) matches for user \(userId).", withIndent:1, withNewline:true)
                if callback != nil {
                    callback!(didError:false)
                }
            } else {
                log("Error \(error!.description) occurred when loading \(userId)'s matches.", withIndent:1, withFlag:"-", withNewline:true)
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
        let predicate:NSPredicate = NSPredicate(format:"voterId = \"\(encodeBase64(rootUser))\"")!
        var query = PFQuery(className:"MatchData", predicate:predicate)
        query.findObjectsInBackgroundWithBlock {
            (objects:[AnyObject]!, error:NSError?) -> Void in
            if error == nil {
                for index:Int in 0..<objects.count {
                    let matchData:AnyObject! = objects[index]
                    let first:UInt64 = uint64FromAnyObject(matchData["firstId"], base64:true)
                    let second:UInt64 = uint64FromAnyObject(matchData["secondId"], base64:true)
                    let titleId:Int = matchData["titleId"] as Int
                    self.tryToUpdateDirectedEdge(first, to:second, voter:rootUser, titleId:titleId)
                    self.tryToUpdateDirectedEdge(second, to:first, voter:rootUser, titleId:titleId)
                    self.userVoteHistory.append((first, second, titleId))
                }
                self.didFetchUserMatchHistory = true
                self.checkMatchesBeforeUserHistoryLoaded()
                log("User voted on \(objects.count) matches.", withIndent:1, withNewline:true)
                if callback != nil {
                    callback!(didError:false)
                }
            } else {
                log("Error \"\(error!.description)\" while fetching user match history.", withIndent:1, withFlag:"-", withNewline:true)
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
            newMatch["firstId"] = encodeBase64(firstId)
            newMatch["secondId"] = encodeBase64(secondId)
            newMatch["voterId"] = encodeBase64(rootUser)
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
        let didUpdateMatch:Bool = matches[from]![to]!.updateMatch(titleId, voter:voter)
        if didUpdateMatch {
            cachedMatchesByTitle[from] = nil
            cachedMatchesByTitle[to] = nil
        }
        return didUpdateMatch
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
    var userVoteHistory:[(UInt64, UInt64, Int)]
    var matchUpdateTimes:[MatchTuple:NSDate]
    
    var cachedMatchesByTitle:[UInt64:[(Int,[(UInt64,Int)])]]
}
