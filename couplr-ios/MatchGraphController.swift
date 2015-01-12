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

    /**
     * Before the app closes, attempt to flush the unregistered matches
     * to Parse.
     */
    public func appWillClose() {
        matches?.flushUnregisteredMatches()
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
        matches!.fetchMatchesForId(SocialGraphController.sharedInstance.rootId())
        matches!.fetchRootUserVoteHistory {
            (didError) -> Void in
            SocialGraphController.sharedInstance.didLoadVoteHistoryOrInitializeGraph()
        }
    }

    /**
     * Query all matches for a given match ID and update the graph
     * accordingly. Invoke the callback function using a dictionary
     * mapping each user the given id is matched with to another
     * dictionary mapping title id to vote count.
     *
     * If the request failed, the resulting argument will be nil.
     */
    public func doAfterLoadingMatchesForId(id:UInt64, callback:([UInt64:[Int:Int]]?) -> Void) {
        matches?.fetchMatchesForId(id, callback: {
            (didError:Bool) -> Void in
            if didError {
                callback(nil)
            } else {
                callback(self.matches?.numMatchesByUserIdAndTitleFor(id))
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
    public func titleList() -> [MatchTitle] {
        if matches == nil {
            return []
        }
        return matches!.titleList
    }

    /**
     * Wraps a call to the same method of MatchGraph.
     */
    public func numMatchesByUserIdAndTitleFor(id:UInt64) -> [UInt64:[Int:Int]] {
        if matches == nil {
            return [UInt64:[Int:Int]]()
        }
        return matches!.numMatchesByUserIdAndTitleFor(id)
    }

    /**
     * Notifies the MatchGraph that the root user performed a match.
     * Will assume that the SocialGraph has already been initialized,
     * so the root user is graph!.root.
     */
    public func userDidMatch(firstId:UInt64, toSecondId:UInt64, withTitleId:Int) {
        matches?.userDidMatch(firstId, toSecondId: toSecondId, withTitleId: withTitleId)
    }
}