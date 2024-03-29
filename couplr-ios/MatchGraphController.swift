//
//  MatchGraphController.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 1/6/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import Parse

public class MatchGraphController {

    var matches: MatchGraph?

    class var sharedInstance: MatchGraphController {
        struct MatchGraphSingleton {
            static let instance = MatchGraphController()
        }
        return MatchGraphSingleton.instance
    }
    
    public func reset() {
        matches = nil
    }

    /**
     * Before the app closes, attempt to flush the unregistered matches
     * to Parse.
     */
    public func appWillHalt() {
        matches?.flushUnregisteredMatches()
        UserSessionTracker.sharedInstance.flushUserSession()
    }
    
    /**
     * Returns a list of recent matches in the user's social network.
     * The matches involve the user's closest friends, and are sorted
     * by chronological order, newest first.
     */
    public func newsfeedMatches(maxNumMatches: Int = kMaxNumNewsfeedMatches) -> [(MatchTuple, NSDate)] {
        if matches == nil {
            log("MatchGraphController::newsfeedMatches called before match graph was initialized.", withFlag: "-")
            return []
        }
        let rootId: UInt64 = SocialGraphController.sharedInstance.rootId()
        var updateTimesByMatchTuple: [MatchTuple: NSDate] = [MatchTuple: NSDate]()
        for friendId: UInt64 in SocialGraphController.sharedInstance.closestFriendsOfUser(rootId) {
            for (neighborId: UInt64, matchList: MatchList) in matches!.matchListsForUserId(friendId) {
                if neighborId == rootId || !SocialGraphController.sharedInstance.hasNameForUser(neighborId) {
                    continue
                }
                for (titleId: Int, _: [UInt64]) in matchList.matchesByTitle {
                    let updateTime: NSDate? = matchList.lastUpdateTimeForTitle(titleId)
                    if updateTime != nil {
                        updateTimesByMatchTuple[MatchTuple(firstId: friendId, secondId: neighborId, titleId: titleId)] = updateTime!
                    }
                }
            }
        }
        var matchTuples: [MatchTuple] = updateTimesByMatchTuple.keys.array
        matchTuples.sort {
            (first: MatchTuple, second: MatchTuple) -> Bool in
            let firstUpdateTime: NSDate = updateTimesByMatchTuple[first]!
            let secondUpdateTime: NSDate = updateTimesByMatchTuple[second]!
            return firstUpdateTime.compare(secondUpdateTime) == .OrderedDescending
        }
        matchTuples = Array(matchTuples[0..<min(matchTuples.count, maxNumMatches)])
        return matchTuples.map { ($0, updateTimesByMatchTuple[$0]!) }
    }
    
    /**
     * Returns the vote history of the root user, sorted by time. The newest votes
     * appear first, and the oldest votes appear last. Returns the data as a list
     * of (MatchTuple, NSDate) pairs.
     */
    public func rootUserVoteHistory() -> [(MatchTuple, NSDate)] {
        if matches == nil {
            log("MatchGraphController::rootUserVoteHistory called before match graph was initialized.", withFlag: "-")
            return []
        }
        let voteHistory: [(MatchTuple, NSDate)] = Array(matches!.userVotes.keys.filter({ (tuple: MatchTuple) -> Bool in
            return self.matches!.userVotes[tuple] != nil &&
                SocialGraphController.sharedInstance.hasNameForUser(tuple.firstId) &&
                SocialGraphController.sharedInstance.hasNameForUser(tuple.secondId)
        }).map {(tuple: MatchTuple) -> (tuple: MatchTuple, time: NSDate) in
            return (tuple, self.matches!.userVotes[tuple]!)
        })
        return sorted(voteHistory, { (firstTupleAndTime:(MatchTuple, NSDate), secondTupleAndTime:(MatchTuple, NSDate)) -> Bool in
            return firstTupleAndTime.1.compare(secondTupleAndTime.1) == .OrderedDescending
        })
    }

    /**
     * Once the social graph loads, we know the root user. Use this
     * to fetch the matches the user's voting history and the matches
     * the user is involved in.
     */
    public func socialGraphDidLoad() {
        if matches == nil {
            matches = MatchGraph()
        }
        matches!.fetchRootUserVoteHistory { (success) -> Void in
            SocialGraphController.sharedInstance.didLoadVoteHistoryOrInitializeGraph()
        }
    }
    
    /**
     * Returns a sorted list of the most recent matches, which contains
     * pairs of (MatchTuple, NSDate) where the NSDate indicates when the
     * match was voted for, and the MatchTuple contains all the relevant
     * information needed to identify a match. The list is sorted by
     * NSDate, where the first elements are the newest matches and the
     * last elements are the oldest matches.
     * 
     * minNumMatches: indicates the minimum number of matches to count as
     *   most recent, given that there are at least that many total matches.
     */
    public func sortedRecentMatchesForUser(userId: UInt64, maxNumMatches: Int = kMaxNumRecentMatches) -> [(MatchTuple, NSDate)] {
        if matches == nil {
            return []
        }
        var recentMatchesAndUpdateTimes: [(MatchTuple, NSDate)] = []
        for (match: MatchTuple, updateTime: NSDate) in matches!.matchUpdateTimes {
            if (match.firstId == userId || match.secondId == userId) && match.shouldDisplay() {
                recentMatchesAndUpdateTimes.append((match, updateTime))
            }
        }
        recentMatchesAndUpdateTimes.sort({
            (first:(MatchTuple, NSDate), second:(MatchTuple, NSDate)) -> Bool in
            return first.1.compare(second.1) == .OrderedDescending
        })
        if recentMatchesAndUpdateTimes.count > maxNumMatches {
            return Array(recentMatchesAndUpdateTimes[0..<maxNumMatches])
        }
        return recentMatchesAndUpdateTimes
    }
    
    /**
     * Wrapper around SocialGraph::rootUserVoteState used to determine whether or
     * not to allow the root user to submit a given match from the newsfeed.
     */
    public func shouldAllowUserToVoteFromNewsfeed(firstId: UInt64, secondId: UInt64, titleId: Int) -> Bool {
        if matches == nil {
            return false
        }
        return matches!.rootUserVoteState(firstId, secondId: secondId, titleId: titleId) == .HasNotVoted
    }

    /**
     * Query all matches for a given match ID and update the graph accordingly.
     * Invokes the callback function with a boolean argument indicating whether
     * the request was successful.
     */
    public func doAfterLoadingMatchesForId(id: UInt64, onComplete: ((success: Bool) -> Void)? = nil) {
        doAfterLoadingMatchesForIds([id], onComplete: onComplete)
    }
    
    /**
     * Same idea as MatchGraphController::doAfterLoadingMatchesForId, but instead
     * of querying just one id, queries a batch of ids.
     */
    public func doAfterLoadingMatchesForIds(ids: [UInt64], onComplete: ((success: Bool) -> Void)? = nil) {
        matches?.fetchMatchesForIds(ids, onComplete: onComplete)
    }
    
    /**
     * Wraps an invocation to MatchGraph::fetchMatchTitles, requiring a
     * callback.
     *
     * TODO Implement "reliability" features here, i.e. resending queries
     * to Parse up to a maximum number of attempts.
     */
    public func fetchMatchTitles(onComplete: ((success: Bool) -> Void)) {
        if matches == nil {
            onComplete(success: false)
        } else {
            matches!.fetchMatchTitles(onComplete: onComplete)
        }
    }

    /**
     * Returns an array of all the titles.
     */
    public func matchTitles() -> [MatchTitle] {
        if matches == nil {
            return []
        }
        return matches!.titleList
    }
    
    /**
     * Returns a MatchTitle object for the given title id.
     */
    public func matchTitleFromId(titleId: Int) -> MatchTitle? {
        return matches!.titlesById[titleId]
    }

    /**
     * Wraps a call to the same method of MatchGraph.
     */
    public func sortedMatchesForUserByTitleId(userId: UInt64) -> [(Int, [(UInt64, Int)])] {
        if matches == nil {
            log("Warning: match graph not yet loaded!", withFlag:"?")
            return [(Int,[(UInt64, Int)])]()
        }
        return matches!.sortedMatchesForUser(userId)
    }
    
    /**
     * Returns a list of [userId, [titleId, count]]. Each userId is paired
     * with a list containing (titleId, count) tuples. The list is sorted
     * by the number of total votes under each user.
     */
    public func sortedMatchesForUserByUserId(userId: UInt64) -> [(UInt64, [(Int, Int)])] {
        if matches == nil {
            log("Warning: match graph not yet loaded!", withFlag:"?")
            return [(UInt64, [(Int, Int)])]()
        }
        var numVotesForUser: [UInt64: Int] = [UInt64: Int]()
        var voteListForUser: [UInt64: [(Int, Int)]] = [UInt64: [(Int, Int)]]()
        for (title: Int, votes: [(UInt64, Int)]) in sortedMatchesForUserByTitleId(userId) {
            for (user: UInt64, count: Int) in votes {
                numVotesForUser[user] = count + (numVotesForUser[user] == nil ? 0 : numVotesForUser[user]!)
                if voteListForUser[user] == nil {
                    voteListForUser[user] = []
                }
                voteListForUser[user]!.append((title, count))
            }
        }
        return sorted(numVotesForUser.keys, {numVotesForUser[$0]! > numVotesForUser[$1]!}).map {($0, voteListForUser[$0]!)}
    }

    /**
     * Notifies the MatchGraph that the root user performed a match.
     * Will assume that the SocialGraph has already been initialized,
     * so the root user is graph!.root.
     */
    public func userDidMatch(from: UInt64, to: UInt64, withTitleId: Int) {
        matches?.userDidMatch(from, to: to, withTitleId: withTitleId)
    }
    
    /**
     * Notifies the MatchGraph that the root user has undone a match.
     * This will not only update the internal data structure, but also
     * make a request to Parse to delete the corresponding match.
     */
    public func userDidUndoMatch(from: UInt64, to: UInt64, withTitleId: Int, onComplete: ((success: Bool) -> Void)? = nil) {
        if matches == nil {
            onComplete?(success: false)
            return log("MatchGraphController::userDidUndoMatch called before the match graph was initialized!", withFlag: "-")
        }
        if matches!.userDidUndoMatch(from, to: to, withTitleId: withTitleId) {
            let rootUser: UInt64 = SocialGraphController.sharedInstance.rootId()
            let matchToRemove: MatchTuple = MatchTuple(firstId: to, secondId: from, titleId: withTitleId, voterId: rootUser)
            // Try to remove the match from Parse.
            var query: PFQuery = PFQuery(className: "MatchData")
            let (rootUserKey, firstKey, secondKey) = (encodeBase64(rootUser), encodeBase64(matchToRemove.firstId), encodeBase64(matchToRemove.secondId))
            query.whereKey("voterId", equalTo: rootUserKey)
            query.whereKey("firstId", equalTo: firstKey)
            query.whereKey("secondId", equalTo: secondKey)
            query.whereKey("titleId", equalTo: withTitleId)
            query.findObjectsInBackgroundWithBlock({ (objects: [AnyObject]!, error: NSError?) -> Void in
                if error != nil {
                    log("Failed to delete [\(firstKey)), \(secondKey), \(withTitleId)]: \(error!.localizedDescription)", withFlag: "-", withIndent: 1)
                    onComplete?(success: false)
                    return
                }
                for index in 0..<objects.count {
                    objects[index].deleteEventually()
                }
                log("Removed \(objects.count) object(s) corresponding to [\(firstKey)), \(secondKey), \(withTitleId)]")
                onComplete?(success: true)
            })
        } else {
            onComplete?(success: false)
        }
    }
    
    /**
     * Called when the social graph is completely finished loading,
     * including data pulled from social networks of friends. Fetches
     * match information for the user's closest friends from Parse.
     */
    public func didFinishLoadingExtendedSocialGraph() {
        let rootId: UInt64 = SocialGraphController.sharedInstance.rootId()
        let friends: [UInt64] = SocialGraphController.sharedInstance.closestFriendsOfUser(rootId)
        matches?.fetchMatchesForIds(friends, onComplete: { (success: Bool) -> Void in
            if success {
                SocialGraphController.sharedInstance.didLoadMatchesForClosestFriends()
                CouplrViewCoordinator.sharedInstance.refreshNewsfeedView()
            }
        })
        CouplrViewCoordinator.sharedInstance.didInitializeSocialNetwork()
    }
}