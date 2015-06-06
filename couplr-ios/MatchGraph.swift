//
//  MatchGraph.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 1/4/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import Parse
import UIKit

public enum VoteState {
    case SavedVote, UnsavedVote, HasNotVoted, ShouldNotAllowVote
}

public class MatchTitle : Equatable {
    public init(id: Int, text: String, picture: String) {
        self.id = id
        self.text = text
        self.picture = picture
    }

    var id: Int
    var text: String
    var picture: String
    
    public func toString() -> String {
        return "[id=\(id), text=\"\(text)\", picture=\"\(picture)\"]"
    }
}

public func ==(lhs: MatchTitle, rhs: MatchTitle) -> Bool {
    return lhs.id == rhs.id && lhs.text == rhs.text && lhs.picture == rhs.picture
}

/**
 * Represents a tuple uniquely identifying a voter who matched two users
 * for some title. Includes the IDs of the two people who were matched,
 * the ID of the voter, and the title id.
 * 
 * The voterId does not need to be specified, in the case that the use of
 * a MatchTuple does not depend on a particular voter. The same goes for
 * the titleId.
 */
public class MatchTuple : Hashable {
    public init(firstId: UInt64, secondId: UInt64, titleId: Int = 0, voterId: UInt64 = 0) {
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
    
    public var hashValue: Int {
        let sum: UInt64 = UInt64.addWithOverflow(UInt64.addWithOverflow(self.firstId, self.secondId).0, self.voterId).0
        return lower32Bits(sum).hashValue + self.titleId
    }
    
    public func toString() -> String {
        return SocialGraphController.sharedInstance.nameFromId(firstId) + " and " +
            SocialGraphController.sharedInstance.nameFromId(secondId) + " for \(titleId) by \(encodeBase64(voterId))"
    }
    
    public func shouldDisplay() -> Bool {
        return SocialGraphController.sharedInstance.hasNameForUser(firstId) &&
            SocialGraphController.sharedInstance.hasNameForUser(secondId)
    }
    
    var firstId: UInt64
    var secondId: UInt64
    var voterId: UInt64
    var titleId: Int
}

public func ==(lhs: MatchTuple, rhs: MatchTuple) -> Bool {
    return lhs.firstId == rhs.firstId && lhs.secondId == rhs.secondId && lhs.voterId == rhs.voterId && lhs.titleId == rhs.titleId
}

/**
 * Represents an edge in the MatchGraph consisting of all the matches
 * between two people in the graph.
 */
public class MatchList {
    public init() {
        self.matchesByTitle = [Int: [UInt64]]()
        self.latestNonRootUpdateTimes = [Int: NSDate]()
    }

    /**
     * Adds a new match between two users. Returns true if the match
     * has been correctly added, otherwise returns false (e.g. if
     * the result already exists).
     */
    public func updateMatch(titleId: Int, voterId: UInt64, updateTime: NSDate? = nil) -> Bool {
        if matchesByTitle[titleId] == nil {
            matchesByTitle[titleId] = []
        }
        let voterList: [UInt64] = matchesByTitle[titleId]!
        if find(voterList, voterId) == nil {
            matchesByTitle[titleId]!.append(voterId)
            if updateTime != nil && shouldUpdateLatestTime(titleId, voterId: voterId, updateTime: updateTime!) {
                latestNonRootUpdateTimes[titleId] = updateTime
            }
            return true
        }
        return false
    }
    
    /**
     * Removes a match that the root user voted on. Returns true if and
     * only if the match actually existed. Observe that we do NOT have to
     * update the last non-root update time for the title, since this
     * operation will only remove matches made by the root user.
     */
    public func removeMatchVotedByRootUser(titleId: Int) -> Bool {
        if matchesByTitle[titleId] == nil {
            return false
        }
        if let index = find(matchesByTitle[titleId]!, SocialGraphController.sharedInstance.rootId()) {
            matchesByTitle[titleId]!.removeAtIndex(index)
            if matchesByTitle[titleId]!.count == 0 {
                matchesByTitle[titleId] = nil
            }
            return true
        }
        return false
    }
    
    /**
     * Computes the last known voter of this pair, excluding matches voted
     * on by the root user. A nil result indicates that only the user voted
     * on this match pair.
     */
    public func lastUpdateTimeForTitle(titleId: Int) -> NSDate? {
        return latestNonRootUpdateTimes[titleId]
    }
    
    /**
     * Returns true iff the given voter has not yet
     */
    public func userDidVote(userId: UInt64, titleId: Int) -> Bool {
        if matchesByTitle[titleId] == nil {
            return false
        }
        return find(matchesByTitle[titleId]!, userId) != nil
    }
    
    private func shouldUpdateLatestTime(titleId: Int, voterId: UInt64, updateTime: NSDate) -> Bool {
        return voterId != SocialGraphController.sharedInstance.rootId() &&
            (latestNonRootUpdateTimes[titleId] == nil || updateTime.compare(latestNonRootUpdateTimes[titleId]!) == .OrderedDescending)
    }

    // Maps a title ID to a list of users who voted for that match.
    var matchesByTitle: [Int: [UInt64]]
    // Maps a title to the last time that it was updated.
    var latestNonRootUpdateTimes: [Int: NSDate]
}

/**
 * Stores matches relevant to the social network as a graph.
 */
public class MatchGraph {
    public init() {
        self.matches = [UInt64: [UInt64: MatchList]]()
        self.titlesById = [Int: MatchTitle]()
        self.titleList = [MatchTitle]()
        self.fetchedIdHistory = Set<UInt64>()
        self.didFetchUserMatchHistory = false
        self.currentlyFlushingMatches = false
        self.unregisteredMatches = Set<MatchTuple>()
        self.matchesBeforeUserHistoryLoaded = Set<MatchTuple>()
        self.matchUpdateTimes = [MatchTuple: NSDate]()
        self.userVotes = [MatchTuple: NSDate]()
    }

    /**
     * Loads match titles from Parse and passes them to a given callback
     * function.
     */
    public func fetchMatchTitles(onComplete: ((success: Bool) -> Void)? = nil) {
        log("Requesting match titles...", withFlag: "!")
        var query = PFQuery(className: "MatchTitle")
        query.findObjectsInBackgroundWithBlock { (objects: [AnyObject]!, error: NSError?) -> Void in
            if error == nil {
                for title: AnyObject in objects {
                    let picture: String = title["picture"]! as! String
                    if !imageExistsWithName(picture) {
                        continue
                    }
                    let titleId: Int = title["titleId"]! as! Int
                    let text: String = title["text"]! as! String
                    self.titlesById[titleId] = MatchTitle(id: titleId, text: text, picture: picture)
                }
                for title: MatchTitle in self.titlesById.values {
                    self.titleList.append(title)
                }
                self.titleList = sorted(self.titleList, {(first: MatchTitle, second: MatchTitle) -> Bool in
                    return first.id < second.id
                })
                log("Received \(objects.count) titles.", withIndent: 1, withNewline: true)
                onComplete?(success: true)
            } else {
                log("Error \"\(error!.description)\" while retrieving titles.", withIndent: 1, withFlag: "-", withNewline: true)
                onComplete?(success: false)
            }
        }
    }

    /**
     * Returns a string representation of this MatchGraph for (mainly) debugging
     * purposes.
     */
    public func toString() -> String {
        var result: String = "MatchGraph({\n"
        for (node: UInt64, neighbors: [UInt64: MatchList]) in matches {
            result += "    \(node)'s matches:\n"
            for (neighbor: UInt64, matchList: MatchList) in neighbors {
                for (titleId: Int, voters: [UInt64]) in matchList.matchesByTitle {
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
    public func sortedMatchesForUser(userId: UInt64) -> [(Int,[(UInt64, Int)])] {
        if matches[userId] == nil {
            return [(Int,[(UInt64, Int)])]()
        }
        var matchResultSet: [Int: [UInt64: Int]] = [Int: [UInt64: Int]]()
        var matchCountsByTitle: [Int: Int] = [Int: Int]()
        for (neighbor: UInt64, list: MatchList) in matches[userId]! {
            // HACK Find a better way of preventing unknown users from showing up in matches.
            if !SocialGraphController.sharedInstance.hasNameForUser(neighbor) {
                continue
            }
            for (titleId: Int, voters: [UInt64]) in list.matchesByTitle {
                if matchResultSet[titleId] == nil {
                    matchResultSet[titleId] = [UInt64: Int]()
                }
                matchResultSet[titleId]![neighbor] = voters.count
                if matchCountsByTitle[titleId] == nil {
                    matchCountsByTitle[titleId] = 0
                }
                matchCountsByTitle[titleId] = matchCountsByTitle[titleId]! + voters.count
            }
        }
        var sortedMatches: [(Int,[(UInt64, Int)])] = [(Int,[(UInt64, Int)])]()
        for (titleId: Int, results: [UInt64: Int]) in matchResultSet {
            var list: [(UInt64, Int)] = [(UInt64, Int)]()
            for (neighbor: UInt64, count: Int) in results {
                list.append((neighbor, count))
            }
            list.sort {
                (first:(UInt64, Int), second:(UInt64, Int)) -> Bool in
                return first.1 > second.1
            }
            sortedMatches += [(titleId, list)]
        }
        sortedMatches.sort {
            (first:(Int,[(UInt64, Int)]), second:(Int,[(UInt64, Int)])) -> Bool in
            return matchCountsByTitle[first.0]! > matchCountsByTitle[second.0]!
        }
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
    public func fetchMatchesForIds(userIds: [UInt64], onComplete: ((success: Bool) -> Void)? = nil) {
        if userIds.count == 0 {
            return log("Skipping match request for 0 users.", withFlag:"-")
        }
        log("Requesting match records for user(s) \(SocialGraphController.sharedInstance.namesFromIds(userIds))", withFlag:"!")
        // Do not re-fetch matches.
        let userIdsToQuery: [UInt64] = userIds.filter {
            (userId: UInt64) -> Bool in
            if self.fetchedIdHistory.contains(userId) {
                log("Skipping match query for user \(SocialGraphController.sharedInstance.namesFromIds(userIds))")
                return false
            }
            return true
        }
        if userIdsToQuery.count == 0 {
            onComplete?(success: true)
            return log("Matches for users \(SocialGraphController.sharedInstance.namesFromIds(userIds))) already loaded.", withIndent: 1, withNewline: true)
        }
        let encodedUserIds: [String] = userIds.map(encodeBase64)
        let predicate: NSPredicate = NSPredicate(format: "firstId IN %@ OR secondId IN %@", encodedUserIds, encodedUserIds)
        var query = PFQuery(className:"MatchData", predicate: predicate)
        query.findObjectsInBackgroundWithBlock { (objects: [AnyObject]!, error: NSError?) -> Void in
            if error == nil {
                var numMatchUpdates: Int = 0
                for index in 0..<objects.count {
                    let matchData: AnyObject! = objects[index]
                    let titleId: Int = matchData["titleId"] as! Int
                    // If the user is on a version that lacks a title icon asset, do not consider
                    // the title in any list of matches.
                    if self.titlesById[titleId] == nil {
                        continue
                    }
                    let first: UInt64 = uint64FromAnyObject(matchData["firstId"], base64: true)
                    let second: UInt64 = uint64FromAnyObject(matchData["secondId"], base64: true)
                    let voter: UInt64 = uint64FromAnyObject(matchData["voterId"], base64: true)
                    self.tryToUpdateMatch(first, secondId: second, voterId: voter, titleId: titleId, time: matchData.updatedAt)
                    numMatchUpdates++
                }
                // Consider a match fetched only after the response arrives.
                for userId: UInt64 in userIdsToQuery {
                    self.fetchedIdHistory.insert(userId)
                }
                log("Received and updated \(numMatchUpdates) matches for users \(SocialGraphController.sharedInstance.namesFromIds(userIdsToQuery)).", withIndent: 1, withNewline: true)
                onComplete?(success: true)
            } else {
                log("Error \(error!.description) occurred when loading matches for \(SocialGraphController.sharedInstance.namesFromIds(userIdsToQuery)).", withIndent: 1, withFlag:"-", withNewline: true)
                onComplete?(success: false)
            }
        }
    }
    
    /**
     * Attempts to update the appropriate match lists with a new match. If the
     * time of the match is given, also updates the time of the match.
     * HACK This method should really be private, but it's public because the
     *   tests need to know how to add matches to the graph.
     */
    public func tryToUpdateMatch(firstId: UInt64, secondId: UInt64, voterId: UInt64, titleId: Int, time: NSDate? = nil) {
        tryToUpdateDirectedEdge(firstId, to: secondId, voter: voterId, titleId: titleId, updateTime: time)
        tryToUpdateDirectedEdge(secondId, to: firstId, voter: voterId, titleId: titleId, updateTime: time)
        matchUpdateTimes[MatchTuple(firstId: firstId, secondId: secondId, titleId: titleId, voterId: voterId)] = time
    }

    /**
     * Queries Parse for the matches the user has voted on, updating the graph
     * correspondingly, and running a given callback function upon receiving a
     * response.
     */
    public func fetchRootUserVoteHistory(onComplete: ((success: Bool) -> Void)? = nil) {
        let rootUser: UInt64 = SocialGraphController.sharedInstance.rootId()
        if rootUser == 0 {
            return log("Warning: MatchGraph::fetchRootUserMatchHistory called before social graph was initialized.", withFlag:"-")
        }
        if didFetchUserMatchHistory {
            return log("Request for user history denied. Already fetched root user history.", withFlag:"?")
        }
        log("Requesting match history for current user.", withFlag:"!")
        let predicate: NSPredicate = NSPredicate(format: "voterId = \"\(encodeBase64(rootUser))\"")
        var query = PFQuery(className:"MatchData", predicate: predicate)
        query.findObjectsInBackgroundWithBlock { (objects: [AnyObject]!, error: NSError?) -> Void in
            if error == nil {
                var numMatchUpdates: Int = 0
                for index: Int in 0..<objects.count {
                    let matchData: AnyObject! = objects[index]
                    let titleId: Int = matchData["titleId"] as! Int
                    // If the user is on a version that lacks a title icon asset, do not consider
                    // the title in any list of matches.
                    if self.titlesById[titleId] == nil {
                        continue
                    }
                    let first: UInt64 = uint64FromAnyObject(matchData["firstId"], base64: true)
                    let second: UInt64 = uint64FromAnyObject(matchData["secondId"], base64: true)
                    let updateTime: NSDate = matchData.updatedAt
                    self.tryToUpdateDirectedEdge(first, to: second, voter: rootUser, titleId: titleId, updateTime: updateTime)
                    self.tryToUpdateDirectedEdge(second, to: first, voter: rootUser, titleId: titleId, updateTime: updateTime)
                    self.userVotes[MatchTuple(firstId: first, secondId: second, titleId: titleId)] = updateTime
                    numMatchUpdates++
                }
                self.didFetchUserMatchHistory = true
                self.checkMatchesBeforeUserHistoryLoaded()
                log("User voted on \(numMatchUpdates) matches.", withIndent: 1, withNewline: true)
                onComplete?(success: true)
            } else {
                log("Error \"\(error!.description)\" while fetching user match history.", withIndent: 1, withFlag:"-", withNewline: true)
                onComplete?(success: false)
            }
        }
    }

    /**
     * Saves all unregistered matches to Parse. Should be invoked when the app
     * is about to close, but can also be invoked periodically to prevent matches
     * from disappearing in the case of a crash.
     */
    public func flushUnregisteredMatches() {
        let rootUser: UInt64 = SocialGraphController.sharedInstance.rootId()
        if rootUser == 0 {
            return log("Warning: MatchGraph::flushUnregisteredMatches called before social graph was initialized.", withFlag: "-")
        }
        if currentlyFlushingMatches {
            return log("Warning: already attempting to flush unregistered matches.", withFlag: "-")
        }
        if unregisteredMatches.count == 0 {
            return log("Warning: no unregistered matches to flush.", withFlag: "!")
        }
        currentlyFlushingMatches = true
        log("Saving \(unregisteredMatches.count) matches to Parse...")
        var newMatches: [PFObject] = [PFObject]()
        for match: MatchTuple in unregisteredMatches {
            var newMatch: PFObject = PFObject(className: "MatchData")
            newMatch["firstId"] = encodeBase64(match.firstId)
            newMatch["secondId"] = encodeBase64(match.secondId)
            newMatch["voterId"] = encodeBase64(rootUser)
            newMatch["titleId"] = match.titleId
            newMatches.append(newMatch)
        }
        PFObject.saveAllInBackground(newMatches, block: { (succeeded: Bool, error: NSError?) -> Void in
            if succeeded && error == nil {
                log("Successfully saved \(self.unregisteredMatches.count) matches to Parse.", withIndent: 1)
                self.unregisteredMatches.removeAll()
                self.matchesBeforeUserHistoryLoaded.removeAll()
                self.currentlyFlushingMatches = false
            } else {
                log("An error occurred while saving to Parse.", withIndent: 1)
            }
        })
    }
    
    /**
     * Attempts to remove the user's vote for a given couple and title. Returns true
     * if and only if a saved match was found and removed from the match graph.
     */
    public func userDidUndoMatch(from: UInt64, to: UInt64, withTitleId: Int) -> Bool {
        let rootUser: UInt64 = SocialGraphController.sharedInstance.rootId()
        if rootUser == 0 {
            log("Warning: MatchGraph::userDidUndoMatch called before social graph was initialized.", withFlag: "-")
            return false
        }
        let matchToRemove: MatchTuple = MatchTuple(firstId: to, secondId: from, titleId: withTitleId)
        var didRemoveMatchFromGraph: Bool = false
        // Attempt to remove any existing edges from the graph.
        if undirectedMatchListExists(from, to: to) {
            didRemoveMatchFromGraph = matches[from]![to]!.removeMatchVotedByRootUser(withTitleId)
                && matches[to]![from]!.removeMatchVotedByRootUser(withTitleId)
            pruneDirectedMatchListIfEmpty(from, to: to)
            pruneDirectedMatchListIfEmpty(to, to: from)
        }
        // Attempt to remove any matches that were going to be flushed to Parse.
        matchesBeforeUserHistoryLoaded.remove(matchToRemove)
        unregisteredMatches.remove(matchToRemove)
        // Update other auxiliary datastructures as necessary.
        userVotes[matchToRemove] = nil
        matchUpdateTimes[MatchTuple(firstId: to, secondId: from, titleId: withTitleId, voterId: rootUser)] = nil
        return didRemoveMatchFromGraph
    }

    /**
     * Attempts to add a new match to the graph. If the match is successfully
     * added and the social graph exists, notifies the social graph about the
     * new match.
     */
    public func userDidMatch(from: UInt64, to: UInt64, withTitleId: Int) -> Bool {
        if from == to {
            log("User voted \(from) with him/herself!", withFlag: "-")
            return false
        }
        let match: MatchTuple = MatchTuple(firstId: from, secondId: to)
        if !didFetchUserMatchHistory {
            matchesBeforeUserHistoryLoaded.insert(MatchTuple(firstId: match.firstId, secondId: match.secondId, titleId: withTitleId))
            return true
        }
        let rootUser: UInt64 = SocialGraphController.sharedInstance.rootId()
        if rootUser == 0 {
            log("Warning: MatchGraph::userDidMatch called before social graph was initialized.", withFlag: "-")
            return false
        }
        if !tryToUpdateDirectedEdge(match.firstId, to: match.secondId, voter: rootUser, titleId: withTitleId) ||
            !tryToUpdateDirectedEdge(match.secondId, to: match.firstId, voter: rootUser , titleId: withTitleId) {
            log("User already voted on [\(match.firstId), \(match.secondId)] with title \"\(titlesById[withTitleId]!.text)\"")
            return true
        }
        unregisteredMatches.insert(MatchTuple(firstId: match.firstId, secondId: match.secondId, titleId: withTitleId))
        userVotes[MatchTuple(firstId: match.firstId, secondId: match.secondId, titleId: withTitleId)] = NSDate()
        CouplrViewCoordinator.sharedInstance.refreshHistoryView()
        SocialGraphController.sharedInstance.userDidMatch(match.firstId, toSecondId: match.secondId)
        return true
    }
    
    /**
     * Returns a dictionary containing MatchLists of each neighbor of the given user.
     */
    public func matchListsForUserId(userId: UInt64) -> [UInt64: MatchList] {
        return matches[userId] == nil ? [UInt64: MatchList]() : matches[userId]!
    }
    
    /**
     * Returns the MatchList between two given nodes. If no matches exist between them,
     * returns nil.
     */
    public subscript(firstId: UInt64, secondId: UInt64) -> MatchList? {
        return matchListsForUserId(firstId)[secondId]
    }
    
    /**
     * Returns a value indicating whether the root user has voted on a given match.
     */
    public func rootUserVoteState(firstId: UInt64, secondId: UInt64, titleId: Int) -> VoteState {
        let rootId: UInt64 = SocialGraphController.sharedInstance.rootId()
        let match: MatchTuple = MatchTuple(firstId: firstId, secondId: secondId, titleId: titleId, voterId: rootId)
        if !match.shouldDisplay() {
            // Do not allow the user to vote on matches with non-visible users.
            return .ShouldNotAllowVote
        }
        if !didFetchUserMatchHistory {
            // Do not allow the user to vote if the user's vote history has not been fetched.
            return .ShouldNotAllowVote
        }
        if unregisteredMatches.contains(match) {
            // The user has voted on the match, but it has not been saved to Parse.
            return .UnsavedVote
        }
        let matchList: MatchList? = self[firstId, secondId]
        if matchList == nil || !matchList!.userDidVote(rootId, titleId: titleId) {
            return .HasNotVoted
        }
        return .SavedVote
    }
    
    /**
     * Removes a *directed* match list iff the match list is completely empty.
     */
    private func pruneDirectedMatchListIfEmpty(from: UInt64, to: UInt64) {
        if matches[from] == nil || matches[from]![to] == nil {
            return
        }
        if matches[from]![to]!.matchesByTitle.count == 0 {
            matches[from]![to] = nil
        }
        if matches[from]!.count == 0 {
            matches[from] = nil
        }
    }    

    /**
     * Updates the graph going in one direction. Returns if the edge was successfully
     * added (i.e. the user did not already vote on the pair for the same title).
     */
    private func tryToUpdateDirectedEdge(from: UInt64, to: UInt64, voter: UInt64, titleId: Int, updateTime: NSDate? = nil) -> Bool {
        // Make a new adjacency map if none exists.
        if matches[from] == nil {
            matches[from] = [UInt64: MatchList]()
        }
        // Make a new MatchList if none exists.
        if matches[from]![to] == nil {
            matches[from]![to] = MatchList()
        }
        let didUpdateMatch: Bool = matches[from]![to]!.updateMatch(titleId, voterId: voter, updateTime: updateTime)
        if didUpdateMatch {
            SocialGraphController.sharedInstance.notifyMatchExistsBetweenUsers(from, secondUser: to, withVoter: voter)
        }
        return didUpdateMatch
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
        let rootUser: UInt64 = SocialGraphController.sharedInstance.rootId()
        if rootUser == 0 {
            return log("Warning: MatchGraph::checkMatchesBeforeUserHistoryLoaded called before social graph was initialized.", withFlag:"-")
        }
        for match: MatchTuple in matchesBeforeUserHistoryLoaded {
            if tryToUpdateDirectedEdge(match.firstId, to: match.secondId, voter: rootUser, titleId: match.titleId) &&
                tryToUpdateDirectedEdge(match.secondId, to: match.firstId, voter: rootUser , titleId: match.titleId) {

                log("Appending buffered match [\(match.firstId), \(match.secondId)] with title \"\(titlesById[match.titleId])\" to unregistered matches.")
                unregisteredMatches.insert(MatchTuple(firstId: match.firstId, secondId: match.secondId, titleId: match.titleId))
            } else {
                log("User already voted on [\(match.firstId), \(match.secondId)] with title \"\(titlesById[match.titleId]!.text)\"")
            }
        }
        matchesBeforeUserHistoryLoaded.removeAll()
    }
    
    /**
     * Returns true iff a MatchList exists going from the first user to the second and
     * from the second user to the first.
     */
    private func undirectedMatchListExists(from: UInt64, to: UInt64) -> Bool {
        return matches[to] != nil && matches[to]![from] != nil && matches[from] != nil && matches[from]![to] != nil
    }

    var matches: [UInt64: [UInt64: MatchList]]
    var titlesById: [Int: MatchTitle]
    var titleList: [MatchTitle]
    var fetchedIdHistory: Set<UInt64>
    var didFetchUserMatchHistory: Bool
    var currentlyFlushingMatches: Bool
    var unregisteredMatches: Set<MatchTuple>
    var userVotes: [MatchTuple: NSDate]
    var matchesBeforeUserHistoryLoaded: Set<MatchTuple>
    var matchUpdateTimes: [MatchTuple: NSDate]
}
