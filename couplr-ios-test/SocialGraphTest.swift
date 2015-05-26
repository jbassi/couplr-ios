//
//  SocialGraphTest.swift
//  couplr-ios-test
//
//  Created by Wenson Hsieh on 5/25/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import XCTest
import couplr_ios

class SocialGraphTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        initializeTestGraph()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testWalkWeightBonuses() {
        initializeTestGraph()
        XCTAssertEqual(graph!.walkWeightBonusForNode(1), 0, "Incorrect walk weight bonus.")
        XCTAssertEqual(graph!.walkWeightBonusForNode(2), 0, "Incorrect walk weight bonus.")
        graph!.userDidMatch(1, toSecondId: 2)
        XCTAssertGreaterThan(graph!.walkWeightBonusForNode(1), 0, "Expected walk weight bonus to increase.")
        XCTAssertGreaterThan(graph!.walkWeightBonusForNode(2), 0, "Expected walk weight bonus to increase.")
    }
    
    func testGraphPruningFromRoot() {
        graph!.connectNode(1, toNode: 2, withWeight: 1)
        graph!.connectNode(1, toNode: 3, withWeight: 1)
        graph!.connectNode(1, toNode: 4, withWeight: 0.5)
        graph!.connectNode(1, toNode: 5, withWeight: 2)
        graph!.connectNode(3, toNode: 4, withWeight: 1)
        graph!.pruneGraphByIsolationFromRoot()
        expectEdgeFrom(1, to: 3, withWeight: 1)
        expectEdgeFrom(3, to: 4, withWeight: 1)
        expectEdgeFrom(1, to: 4, withWeight: 0.5)
        expectNoEdgeFrom(1, to: 2)
        expectNoEdgeFrom(1, to: 5)
    }
    
    func testGraphPruningByWeight() {
        graph!.connectNode(1, toNode: 2, withWeight: 1)
        graph!.connectNode(1, toNode: 3, withWeight: 0.25)
        graph!.connectNode(1, toNode: 4, withWeight: 0.5)
        graph!.connectNode(1, toNode: 5, withWeight: 2)
        graph!.connectNode(3, toNode: 4, withWeight: 1.1)
        graph!.pruneGraphByMinWeightThreshold(minWeight: 1)
        expectEdgeFrom(1, to: 2, withWeight: 1)
        expectEdgeFrom(1, to: 5, withWeight: 2)
        expectEdgeFrom(3, to: 4, withWeight: 1.1)
        expectNoEdgeFrom(1, to: 3)
        expectNoEdgeFrom(1, to: 4)
    }
    
    func testGraphWeightBaseline() {
        XCTAssert(graph!.baselineEdgeWeight() == 0, "Incorrect baseline edge weight.")
        graph!.connectNode(1, toNode: 2, withWeight: 1)
        graph!.connectNode(1, toNode: 3, withWeight: 1)
        graph!.connectNode(1, toNode: 4, withWeight: 5)
        graph!.connectNode(1, toNode: 5, withWeight: 2)
        graph!.connectNode(2, toNode: 3, withWeight: 0.5)
        graph!.connectNode(3, toNode: 4, withWeight: 1)
        graph!.connectNode(2, toNode: 5, withWeight: 0.25)
        XCTAssertEqualWithAccuracy(graph!.baselineEdgeWeight(), 0.583, 0.001, "Incorrect baseline edge weight.")
        graph!.connectNode(2, toNode: 5, withWeight: 1)
        XCTAssertEqualWithAccuracy(graph!.baselineEdgeWeight(), 0.917, 0.001, "Incorrect baseline edge weight.")
    }
    
    func testUpdateGenders() {
        let expectation = expectationWithDescription("Expected genders to update.")
        graph!.updateNodeWithId(6, andName: "Grace Hopper")
        graph!.updateNodeWithId(7, andName: "Dennis Ritchie")
        graph!.updateNodeWithId(8, andName: "Margaret Hamilton")
        graph!.updateNodeWithId(9, andName: "Radia Perlman")
        graph!.updateGenders { success in
            expectation.fulfill()
        }
        waitForExpectationsWithTimeout(5, handler: { error in
            XCTAssertNil(error, "An error occurred when testing gender updates.")
            for node: UInt64 in [1, 3, 4, 5, 7] {
                XCTAssertEqual(self.graph!.genderFromId(node), .Male, "Expected node \(node) to map to male.")
            }
            for node: UInt64 in [2, 6, 8, 9] {
                XCTAssertEqual(self.graph!.genderFromId(node), .Female, "Expected node \(node) to map to female.")
            }
        })
    }
    
    private func expectNoEdgeFrom(from: UInt64, to: UInt64) {
        XCTAssertFalse(graph!.hasEdgeFromNode(from, to: to), "Expected no edge from node \(from) to \(to).")
        XCTAssertFalse(graph!.hasEdgeFromNode(to, to: from), "Expected no edge from node \(to) to \(from).")
    }
    
    private func expectEdgeFrom(from: UInt64, to: UInt64, withWeight: Float? = nil) {
        XCTAssert(graph!.hasEdgeFromNode(from, to: to), "Expected edge from node \(from) to \(to).")
        XCTAssert(graph!.hasEdgeFromNode(to, to: from), "Expected edge from node \(to) to \(from).")
        if withWeight != nil {
            XCTAssertEqual(graph![from, to], withWeight!, "Expected edge \(from), \(to) with weight \(withWeight).")
            XCTAssertEqual(graph![to, from], withWeight!, "Expected edge \(to), \(from) with weight \(withWeight).")
        }
    }
    
    private func initializeTestGraph() {
        graph = SocialGraph(root: 1, nodes: [
            1: "Alan Turing",
            2: "Ada Lovelace",
            3: "Tim Berners Lee",
            4: "Donald Knuth",
            5: "Edsger Wybe Dijkstra"
        ])
    }
    
    var graph: SocialGraph?
}
