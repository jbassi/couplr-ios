//
//  MatchGraphTest.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 5/25/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import XCTest
import couplr_ios

class MatchGraphTest: XCTestCase {

    override func setUp() {
        super.setUp()
        matches = MatchGraph()
    }
    
    func testMatchTuple() {
        let m1 = MatchTuple(firstId: 1002, secondId: 2001, titleId: 1, voterId: 500)
        XCTAssertEqual(m1, MatchTuple(firstId: 1002, secondId: 2001, titleId: 1, voterId: 500), "Expected match tuples to be equal.")
        XCTAssertEqual(m1, MatchTuple(firstId: 2001, secondId: 1002, titleId: 1, voterId: 500), "Expected match tuples to be equal.")
        XCTAssertNotEqual(m1, MatchTuple(firstId: 1002, secondId: 2001, titleId: 1, voterId: 501), "Expected match tuples to be different.")
        let m2 = MatchTuple(firstId: 1002, secondId: 2001, titleId: 1)
        XCTAssertEqual(m2, MatchTuple(firstId: 2001, secondId: 1002, titleId: 1), "Expected match tuples to be equal.")
        XCTAssertNotEqual(m2, MatchTuple(firstId: 2001, secondId: 1003, titleId: 2), "Expected match tuples to be different.")
        let m3 = MatchTuple(firstId: 1002, secondId: 2001)
        XCTAssertEqual(m3, MatchTuple(firstId: 1002, secondId: 2001), "Expected match tuples to be equal.")
        XCTAssertNotEqual(m3, MatchTuple(firstId: 1002, secondId: 2000), "Expected match tuples to be different.")
    }
    
    func testMatchList() {
        SocialGraphController.get().setSocialGraph(SocialGraph(root: 10, nodes: [10: "Hello World"]))
        var matchlist = MatchList()
        matchlist.updateMatch(1, voterId: 10, updateTime: NSDate(timeIntervalSinceNow: 3600))
        matchlist.updateMatch(2, voterId: 20, updateTime: NSDate(timeIntervalSinceNow: 7200))
        matchlist.updateMatch(2, voterId: 30, updateTime: NSDate())
        expectDatesToMatch(matchlist.lastUpdateTimeForTitle(2)!, NSDate(timeIntervalSinceNow: 7200), "Latest update time incorrect.")
        XCTAssertNil(matchlist.lastUpdateTimeForTitle(1), "Expected latest update time to be nil.")
        XCTAssertFalse(matchlist.removeMatchVotedByRootUser(2))
        XCTAssert(matchlist.removeMatchVotedByRootUser(1))
    }
    
    func testUserDidMatch() {
        SocialGraphController.get().setSocialGraph(SocialGraph(root: 10, nodes: [10: "Hello World"]))
        matches!.setDidFetchUserMatchHistory(true)
        matches!.userDidMatch(20, to: 30, withTitleId: 1)
        matches!.userDidMatch(20, to: 30, withTitleId: 2)
        matches!.userDidMatch(20, to: 40, withTitleId: 2)
        matches!.userDidMatch(40, to: 50, withTitleId: 3)
        expectUserToHave(10, numMatches: 0)
        expectUserToHave(20, numMatches: 2)
        expectUserToHave(30, numMatches: 1)
        expectUserToHave(40, numMatches: 2)
    }
    
    func testUserDidUndoMatch() {
        SocialGraphController.get().setSocialGraph(SocialGraph(root: 10, nodes: [10: "Hello World"]))
        matches!.setDidFetchUserMatchHistory(true)
        matches!.userDidMatch(20, to: 30, withTitleId: 1)
        matches!.userDidMatch(20, to: 30, withTitleId: 2)
        matches!.userDidMatch(20, to: 40, withTitleId: 2)
        matches!.userDidMatch(20, to: 50, withTitleId: 3)
        matches!.userDidUndoMatch(20, to: 30, withTitleId: 1)
        matches!.userDidUndoMatch(20, to: 50, withTitleId: 3)
        matches!.userDidUndoMatch(20, to: 30, withTitleId: 3) // Should be no-op.
        expectUserToHave(20, numMatches: 2)
        expectUserToHave(30, numMatches: 1)
        expectUserToHave(40, numMatches: 1)
        expectUserToHave(50, numMatches: 0)
    }
    
    // Note that this does not check that the matches are received in the correct order.
    func testSortedMatchesByTitle() {
        SocialGraphController.get().setSocialGraph(SocialGraph(root: 10, nodes: [
            10: "Hello World",
            20: "Foo Bar",
            30: "Gar Ply",
            40: "Fizz Buzz" // Notice we have no knowledge of user 50.
        ]))
        matches!.setDidFetchUserMatchHistory(true)
        matches!.userDidMatch(20, to: 30, withTitleId: 1)
        matches!.userDidMatch(20, to: 30, withTitleId: 2)
        matches!.userDidMatch(20, to: 40, withTitleId: 2)
        matches!.userDidMatch(20, to: 50, withTitleId: 3)
        matches!.userDidMatch(20, to: 50, withTitleId: 4)
        let sortedMatches = matches!.sortedMatchesForUser(20)
        var sortedMatchesByTitle: [Int: [(UInt64, Int)]] = [Int: [(UInt64, Int)]]()
        for (titleId: Int, matches: [(UInt64, Int)]) in sortedMatches {
            sortedMatchesByTitle[titleId] = matches
        }
        XCTAssertEqual(sortedMatchesByTitle.count, 2, "Wrong number of elements.")
        XCTAssert(sortedMatchesByTitle[1] != nil, "Expected sortedMatchesByTitle[1] to contain elements.")
        XCTAssert(sortedMatchesByTitle[2] != nil, "Expected sortedMatchesByTitle[2] to contain elements.")
        XCTAssertEqual(sortedMatchesByTitle[1]![0].0, 30, "Incorrect user in sorted matches for title 1.")
        XCTAssertEqual(sortedMatchesByTitle[1]![0].1, 1, "Incorrect count in sorted matches for title 1.")
        XCTAssertEqual(sortedMatchesByTitle[2]!.count, 2, "Incorrect number of matches for title 2.")
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    private func expectUserToHave(userId: UInt64, numMatches: Int) {
        XCTAssertEqual(matches!.matchListsForUserId(userId).count, numMatches, "Expected \(userId) to have \(numMatches) matches.")
    }
    
    var matches:MatchGraph? = nil
}
