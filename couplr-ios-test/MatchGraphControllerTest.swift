//
//  MatchGraphControllerTest.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 5/26/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import XCTest
import couplr_ios

class MatchGraphControllerTest: XCTestCase {

    override func setUp() {
        super.setUp()
        titles = [MatchTitle(id: 1, text: "Terrible couple", picture: "one.svg"),
            MatchTitle(id: 2, text: "Weird couple", picture: "two.svg"),
            MatchTitle(id: 3, text: "Awesome couple", picture: "three.svg"),
            MatchTitle(id: 4, text: "Cute couple", picture: "four.svg"),
            MatchTitle(id: 5, text: "Smart couple", picture: "five.svg"),
            MatchTitle(id: 6, text: "Perfect couple", picture: "six.svg"),
            MatchTitle(id: 7, text: "Quiet couple", picture: "seven.svg")]
        graph = SocialGraph(root: 1, nodes: [
            1: "Alan Turing",
            2: "Ada Lovelace",
            3: "Tim Berners Lee",
            4: "Donald Knuth",
            5: "Margaret Hamilton",
            6: "Edsger Wybe Dijkstra",
            7: "Steve Wozniak",
            8: "Dennis Ritchie",
            9: "Grace Hopper"
        ])
        graph!.connectNode(1, toNode: 2, withWeight: 2)
        graph!.connectNode(1, toNode: 3, withWeight: 2)
        graph!.connectNode(1, toNode: 4, withWeight: 5)
        graph!.connectNode(1, toNode: 5, withWeight: 1)
        graph!.connectNode(1, toNode: 6, withWeight: 3)
        graph!.connectNode(1, toNode: 7, withWeight: 5)
        graph!.connectNode(2, toNode: 3, withWeight: 1)
        graph!.connectNode(2, toNode: 8, withWeight: 0.5)
        graph!.connectNode(3, toNode: 8, withWeight: 0.8)
        graph!.connectNode(4, toNode: 9, withWeight: 0.4)
        graph!.connectNode(5, toNode: 7, withWeight: 1)
        SocialGraphController.get().setSocialGraph(graph!)
        matches = MatchGraph()
        matches!.setDidFetchUserMatchHistory(true)
        matches!.tryToUpdateMatch(1, secondId: 3, voterId: 2, titleId: 2, time: NSDate(timeIntervalSinceNow: 3600))
        matches!.tryToUpdateMatch(1, secondId: 3, voterId: 6, titleId: 1, time: NSDate(timeIntervalSinceNow: 14400))
        matches!.tryToUpdateMatch(1, secondId: 8, voterId: 2, titleId: 1, time: NSDate(timeIntervalSinceNow: 10800))
        matches!.tryToUpdateMatch(1, secondId: 8, voterId: 6, titleId: 1, time: NSDate(timeIntervalSinceNow: 7200))
        matches!.userDidMatch(4, to: 6, withTitleId: 5)
        matches!.userDidMatch(4, to: 6, withTitleId: 6)
        matches!.tryToUpdateMatch(4, secondId: 9, voterId: 3, titleId: 7, time: NSDate())
        matches!.tryToUpdateMatch(4, secondId: 9, voterId: 8, titleId: 7, time: NSDate(timeIntervalSinceNow: 60))
        matches!.userDidMatch(5, to: 7, withTitleId: 3)
        matches!.tryToUpdateMatch(5, secondId: 7, voterId: 9, titleId: 3, time: NSDate(timeIntervalSinceNow: 120))
        matches!.setMatchTitles(titles!)
        controller.setMatchGraph(matches!)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testMatchTitles() {
        XCTAssertEqual(controller.matchTitleFromId(3)!, MatchTitle(id: 3, text: "Awesome couple", picture: "three.svg"), "Incorrect match title.")
        XCTAssertEqual(controller.matchTitleFromId(5)!, MatchTitle(id: 5, text: "Smart couple", picture: "five.svg"), "Incorrect match title.")
        XCTAssertEqual(controller.matchTitles(), titles!, "Incorrect list of match titles.")
    }
    
    func testRootUserVoteHistory() {
        var votes: [MatchTuple] = sorted(controller.rootUserVoteHistory().map{ $0.0 }, { $0.toString() < $1.toString() })
        XCTAssertEqual(votes.count, 3, "Expected to find 3 matches.")
        XCTAssertEqual(votes[0], MatchTuple(firstId: 4, secondId: 6, titleId: 5), "Incorrect match in vote history.")
        XCTAssertEqual(votes[1], MatchTuple(firstId: 4, secondId: 6, titleId: 6), "Incorrect match in vote history.")
        XCTAssertEqual(votes[2], MatchTuple(firstId: 5, secondId: 7, titleId: 3), "Incorrect match in vote history.")
        matches!.userDidUndoMatch(4, to: 6, withTitleId: 6)
        votes = sorted(controller.rootUserVoteHistory().map{ $0.0 }, { $0.toString() < $1.toString() })
        XCTAssertEqual(votes.count, 2, "Expected to find 2 matches.")
        XCTAssertEqual(votes[0], MatchTuple(firstId: 4, secondId: 6, titleId: 5), "Incorrect match in vote history.")
        XCTAssertEqual(votes[1], MatchTuple(firstId: 5, secondId: 7, titleId: 3), "Incorrect match in vote history.")
    }
    
    func testRootUserRecentMatches() {
        var recentMatches: [MatchTuple] = controller.rootUserRecentMatches(maxNumMatches: 6).map{ $0.0 }
        XCTAssertEqual(recentMatches.count, 4, "Should return the minimum of the given max and the total number of matches.")
        recentMatches = controller.rootUserRecentMatches(maxNumMatches: 2).map{ $0.0 }
        XCTAssertEqual(recentMatches.count, 2, "Should return the minimum of the given max and the total number of matches.")
        XCTAssertEqual(recentMatches[0], MatchTuple(firstId: 1, secondId: 3, voterId: 6, titleId: 1), "Should return the most recent matches.")
        XCTAssertEqual(recentMatches[1], MatchTuple(firstId: 1, secondId: 8, voterId: 2, titleId: 1), "Should return the most recent matches.")
    }
    
    /**
     * There is no strict definition of a "Newsfeed match." In general, the newsfeed should
     * show matches that are relevant to the user. In this particular test case, the root user
     * would probably want to know about the matches of users 4 and 7.
     */
    func testNewsfeedMatches() {
        let matches: [(MatchTuple, NSDate)] = controller.newsfeedMatches(maxNumMatches: 2)
        XCTAssertEqual(matches.count, 2, "Expected 2 newsfeed matches.")
        XCTAssertEqual(matches[0].0, MatchTuple(firstId: 5, secondId: 7, titleId: 3), "Incorrect newsfeed match.")
        XCTAssertEqual(matches[1].0, MatchTuple(firstId: 4, secondId: 9, titleId: 7), "Incorrect newsfeed match.")
        expectDatesToMatch(matches[0].1, NSDate(timeIntervalSinceNow: 120), "Incorrect newsfeed match time.")
        expectDatesToMatch(matches[1].1, NSDate(timeIntervalSinceNow: 60), "Incorrect newsfeed match time.")
    }
    
    func testSortedMatchesByUser() {
        matches!.tryToUpdateMatch(1, secondId: 3, voterId: 4, titleId: 2, time: NSDate())
        matches!.tryToUpdateMatch(1, secondId: 8, voterId: 4, titleId: 1, time: NSDate())
        matches!.tryToUpdateMatch(1, secondId: 4, voterId: 7, titleId: 3, time: NSDate())
        matches!.tryToUpdateMatch(1, secondId: 8, voterId: 7, titleId: 1, time: NSDate())
        let sortedMatches = controller.sortedMatchesForUserByUserId(1)
        XCTAssertEqual(sortedMatches.count, 3, "Expected sorted matches to have 3 elements.")
        XCTAssertEqual(sortedMatches[0].1.count, 1, "Expected the first element of sorted matches to have 3 elements.")
        XCTAssertEqual(sortedMatches[1].1.count, 2, "Expected the second element of sorted matches to have 3 elements.")
        XCTAssertEqual(sortedMatches[2].1.count, 1, "Expected the third element of sorted matches to have 3 elements.")
        XCTAssertEqual(sortedMatches[0].0, 8, "Expected the first element to contain user id 8.")
        XCTAssertEqual(sortedMatches[1].0, 3, "Expected the second element to contain user id 3.")
        XCTAssertEqual(sortedMatches[2].0, 4, "Expected the third element to contain user id 4.")
    }
    
    var controller: MatchGraphController = MatchGraphController.get()
    var graph: SocialGraph? = nil
    var matches: MatchGraph? = nil
    var titles: [MatchTitle]? = nil
}
