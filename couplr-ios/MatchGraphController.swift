//
//  MatchGraphController.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 1/6/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

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
    }
    
    /**
     * Returns a list of recent matches in the user's social network.
     * The matches involve the user's closest friends, and are sorted
     * by chronological order, newest first.
     */
    public func newsFeedMatches(maxNumMatches:Int = kMaxNumNewsFeedMatches) -> [(MatchTuple,NSDate)] {
        if matches == nil {
            return []
        }
        let rootId:UInt64 = SocialGraphController.sharedInstance.rootId()
        var updateTimesByMatchTuple:[MatchTuple:NSDate] = [MatchTuple:NSDate]()
        for friendId:UInt64 in SocialGraphController.sharedInstance.closestFriendsOfUser(rootId) {
            for (neighborId:UInt64, matchList:MatchList) in matches!.matchListsForUserId(friendId) {
                if neighborId == rootId || !SocialGraphController.sharedInstance.hasNameForUser(neighborId) {
                    continue
                }
                for (titleId:Int, _:[UInt64]) in matchList.matchesByTitle {
                    let updateTime:NSDate? = matchList.lastUpdateTimeForTitle(titleId)
                    if updateTime != nil {
                        updateTimesByMatchTuple[MatchTuple(firstId: friendId, secondId: neighborId, titleId: titleId)] = updateTime!
                    }
                }
            }
        }
        var matchTuples:[MatchTuple] = updateTimesByMatchTuple.keys.array
        matchTuples.sort {
            (first:MatchTuple, second:MatchTuple) -> Bool in
            let firstUpdateTime:NSDate = updateTimesByMatchTuple[first]!
            let secondUpdateTime:NSDate = updateTimesByMatchTuple[second]!
            return firstUpdateTime.compare(secondUpdateTime) == .OrderedDescending
        }
        matchTuples = Array(matchTuples[0..<min(matchTuples.count, maxNumMatches)])
        return matchTuples.map { ($0, updateTimesByMatchTuple[$0]!) }
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
        matches!.fetchRootUserVoteHistory {
            (didError) -> Void in
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
    public func recentMatches(minNumMatches:Int = kMinNumRecentMatches) -> [(MatchTuple,NSDate)] {
        if matches == nil {
            return []
        }
        let rootId:UInt64 = SocialGraphController.sharedInstance.rootId()
        var recentMatchesAndUpdateTimes:[(MatchTuple,NSDate)] = []
        for (match:MatchTuple, updateTime:NSDate) in matches!.matchUpdateTimes {
            if match.firstId == rootId || match.secondId == rootId {
                recentMatchesAndUpdateTimes.append((match, updateTime))
            }
        }
        recentMatchesAndUpdateTimes.sort({
            (first:(MatchTuple, NSDate), second:(MatchTuple, NSDate)) -> Bool in
            return first.1.compare(second.1) == .OrderedDescending
        })
        if recentMatchesAndUpdateTimes.count > minNumMatches {
            let timeThreshold:NSDate = recentMatchesAndUpdateTimes[minNumMatches].1
            recentMatchesAndUpdateTimes.filter({
                (tupleAndDate:(MatchTuple, NSDate)) -> Bool in
                let timeComparison:NSComparisonResult = tupleAndDate.1.compare(timeThreshold)
                return timeComparison == .OrderedDescending || timeComparison == .OrderedSame
            })
        }
        return recentMatchesAndUpdateTimes
    }

    /**
     * Query all matches for a given match ID and update the graph
     * accordingly. Invoke the callback function using a dictionary
     * mapping each user the given id is matched with to another
     * dictionary mapping title id to vote count.
     *
     * If the request failed, the resulting argument will be nil.
     */
    public func doAfterLoadingMatchesForId(id:UInt64, callback:([(Int,[(UInt64,Int)])]?) -> Void) {
        matches?.fetchMatchesForIds([id], callback: {
            (didError:Bool) -> Void in
            if didError {
                callback(nil)
            } else {
                callback(self.matches?.sortedMatchesForUser(id))
            }
        })
    }
    
    /**
     * Wraps an invocation to MatchGraph::fetchMatchTitles, requiring a
     * callback.
     *
     * TODO Implement "reliability" features here, i.e. resending queries
     * to Parse up to a maximum number of attempts.
     */
    public func fetchMatchTitles(callback:((didError:Bool)->Void)) {
        if matches == nil {
            callback(didError: true)
        } else {
            matches!.fetchMatchTitles(callback: callback)
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
    public func matchTitleFromId(titleId:Int) -> MatchTitle? {
        return matches!.titlesById[titleId]
    }

    /**
     * Wraps a call to the same method of MatchGraph.
     */
    public func sortedMatchesForUser(userId:UInt64) -> [(Int,[(UInt64,Int)])] {
        if matches == nil {
            log("Warning: match graph not yet loaded!", withFlag:"?")
            return [(Int,[(UInt64,Int)])]()
        }
        return matches!.sortedMatchesForUser(userId)
    }

    /**
     * Notifies the MatchGraph that the root user performed a match.
     * Will assume that the SocialGraph has already been initialized,
     * so the root user is graph!.root.
     */
    public func userDidMatch(firstId:UInt64, toSecondId:UInt64, withTitleId:Int) {
        matches?.userDidMatch(firstId, toSecondId: toSecondId, withTitleId: withTitleId)
    }
    
    /**
     * Called when the social graph is completely finished loading,
     * including data pulled from social networks of friends. Fetches
     * match information for the user's closest friends from Parse.
     */
    public func didFinishLoadingExtendedSocialGraph() {
        let rootId:UInt64 = SocialGraphController.sharedInstance.rootId()
        let friends:[UInt64] = SocialGraphController.sharedInstance.closestFriendsOfUser(rootId)
        matches?.fetchMatchesForIds(friends, callback: {
            (didError:Bool) -> Void in
            if !didError {
                SocialGraphController.sharedInstance.didLoadMatchesForClosestFriends()
                CouplrControllers.sharedInstance.refreshNewsfeedView()
            }
        })
    }
}