//
//  SocialGraphControllerTest.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 5/25/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import XCTest
import couplr_ios

class SocialGraphControllerTest: XCTestCase {
    
    override func setUp() {
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
        graph!.connectNode(1, toNode: 3, withWeight: 4)
        graph!.connectNode(1, toNode: 4, withWeight: 2)
        graph!.connectNode(1, toNode: 5, withWeight: 1)
        graph!.connectNode(1, toNode: 6, withWeight: 3)
        graph!.connectNode(1, toNode: 7, withWeight: 2)
        graph!.connectNode(2, toNode: 3, withWeight: 1)
        graph!.connectNode(2, toNode: 8, withWeight: 0.5)
        graph!.connectNode(3, toNode: 8, withWeight: 0.8)
        graph!.connectNode(4, toNode: 9, withWeight: 0.4)
        graph!.connectNode(5, toNode: 7, withWeight: 1)
        controller.setSocialGraph(graph!)
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    func testNodeNames() {
        XCTAssertEqual(controller.nameFromId(6), "Edsger Wybe Dijkstra", "Incorrect name.")
        XCTAssertEqual(controller.nameFromId(6, maxStringLength: 18), "Edsger W. Dijkstra", "Incorrect name.")
        XCTAssertEqual(controller.nameFromId(6, maxStringLength: 10), "Edsger D.", "Incorrect name.")
    }
    
    func testNotifyMatchBetweenUsers() {
        controller.notifyMatchExistsBetweenUsers(1, secondUser: 9, withVoter: 2)
        XCTAssertGreaterThan(graph![1, 9], 0, "Expected match to add an edge between 1 and 9.")
        controller.notifyMatchExistsBetweenUsers(4, secondUser: 5, withVoter: 1)
        XCTAssertLessThan(graph![4, 5], 0, "Expected match to not add an edge between 4 and 5.")
    }
    
    func testClosestFriends() {
        XCTAssertEqual(controller.closestFriendsOfUser(1, maxNumFriends: 2), [3, 6], "Incorrect closest friends returned.")
        graph!.connectNode(1, toNode: 7, withWeight: 3)
        XCTAssertEqual(controller.closestFriendsOfUser(1, maxNumFriends: 3), [7, 3, 6], "Incorrect closest friends returned.")
        XCTAssertEqual(controller.closestFriendsOfUser(9, maxNumFriends: 2), [4], "Expected only one closest friend.")
    }
    
    func testUpdateRandomSample() {
        graph!.updateNodeWithId(10, andName: "John von Neumann")
        graph!.connectNode(1, toNode: 10, withWeight: 2)
        controller.updateRandomSample()
        XCTAssertEqual(sorted(controller.currentSample()), [2, 3, 4, 5, 6, 7, 8, 9, 10], "Expected the random sample to contain all the other users.")
        for node:UInt64 in 2...10 {
            XCTAssertLessThan(graph!.walkWeightBonusForNode(node), 0, "Expected a walk weight penalty for node \(node)")
        }
        controller.updateRandomSample(keepUsersAtIndices: [(5, 0), (2, 1), (4, 2)])
        XCTAssertEqual(controller.currentSample()[0..<3], [5, 2, 4], "Expected the random sample to retain given users and indices.")
        controller.updateRandomSample()
        for node:UInt64 in 2...10 {
            XCTAssertLessThan(graph!.walkWeightBonusForNode(node), 0, "Expected a walk weight penalty for node \(node)")
            XCTAssertGreaterThan(graph!.walkWeightBonusForNode(node), -1, "Expected walk weight penalty for node \(node) to not be below -1.")
        }
    }
    
    var controller: SocialGraphController = SocialGraphController.get()
    var graph: SocialGraph? = nil
}