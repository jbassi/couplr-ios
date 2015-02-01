//
//  SocialGraphController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/30/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit
import CoreData

protocol SocialGraphControllerDelegate: class {
    func socialGraphControllerDidLoadSocialGraph(graph: SocialGraph)
}

public class SocialGraphController {

    weak var delegate:SocialGraphControllerDelegate?
    var graph:SocialGraph?
    var voteHistoryOrPhotoDataLoadProgress:Int = 0
    var graphSerializationSemaphore = dispatch_semaphore_create(1)
    var graphInitializeBeginTime:Double = 0
    var doBuildGraphFromCoreData:Bool = false

    lazy var managedObjectContext:NSManagedObjectContext? = {
        let appDelegate = UIApplication.sharedApplication().delegate as AppDelegate
        if let managedObjectContext = appDelegate.managedObjectContext {
            return managedObjectContext
        }
        else {
            return nil
        }
    }()

    class var sharedInstance: SocialGraphController {
        struct SocialGraphSingleton {
            static let instance = SocialGraphController()
        }
        return SocialGraphSingleton.instance
    }

    /**
     * Makes a request for the current user's ID and compares it against
     * root information (if any) in local storage to deterine whether we
     * can initialize the graph from local storage. If not, initializes
     * the graph by querying Facebook for status and photo information.
     */
    public func initializeGraph() {
        FBRequestConnection.startWithGraphPath("me?fields=id",
            completionHandler: { (connection, result, error) -> Void in
                if error == nil {
                    let root:UInt64 = uint64FromAnyObject(result["id"])
                    MatchGraphController.sharedInstance.matches!.fetchMatchesForId(root)
                    self.doBuildGraphFromCoreData = self.shouldInitializeGraphFromCoreData(root)
                    if self.doBuildGraphFromCoreData {
                        self.initializeGraphFromCoreData(root)
                    } else {
                        self.graph = SocialGraph(root: root, names: Dictionary<UInt64, String>())
                        self.graph!.updateGraphUsingStatuses()
                    }
                }
        } as FBRequestHandler)
    }

    /**
     * Notifies this controller that the match graph finished loading
     * the root user's match history. When both the vote history and
     * photo data are loaded, adds edges from the user's matches to
     * the graph and exports the results to Parse.
     */
    public func didLoadVoteHistoryOrInitializeGraph() {
        dispatch_semaphore_wait(graphSerializationSemaphore, DISPATCH_TIME_FOREVER)
        voteHistoryOrPhotoDataLoadProgress++
        if voteHistoryOrPhotoDataLoadProgress == 2 {
            // Both vote history and photo data are finished loading.
            let voteHistory:[(UInt64, UInt64, Int)] = MatchGraphController.sharedInstance.matches!.userVoteHistory
            for (firstId:UInt64, secondId:UInt64, titleId:Int) in voteHistory {
                // For each match the user makes, connect the matched nodes.
                if graph!.names[firstId] != nil && graph!.names[secondId] != nil {
                    graph!.connectNode(firstId, toNode: secondId, withWeight: kUserMatchVoteScore)
                }
            }
            if doBuildGraphFromCoreData {
                // No need to export graph data. Just update from friends directly.
                graph!.updateGraphDataFromFriends()
            } else {
                // Export the graph and then update from friends.
                graph!.exportGraphToParse(andLoadFriendGraphs: true)
            }
            // Prevent the graph from saving again under any condition.
            voteHistoryOrPhotoDataLoadProgress = 3
        }
        dispatch_semaphore_signal(graphSerializationSemaphore)
    }

    /**
     * Make the graph update its current random walk sample.
     *
     * TODO Implement sample history and prevent the user from
     * encountering repetitive samples here.
     */
    public func updateRandomSample() {
        graph?.updateRandomSample()
    }

    /**
     * Returns the current sample as a list of IDs, or an empty
     * list if the graph has not been initialized yet.
     */
    public func currentSample() -> [UInt64] {
        if graph == nil {
            return [UInt64]()
        }
        return graph!.currentSample
    }

    /**
     * Given an ID, returns the corresponding full name.
     * If the name is longer than a given maximum, truncates parts
     * of the name until it fits. Starts by making the middle name
     * (if it exists) a middle initial, and then the last name an
     * initial.
     */
    public func nameFromId(id:UInt64, maxStringLength:Int = kMaxNameDisplayLength) -> String {
        if graph == nil || graph!.names[id] == nil {
            return ""
        }
        var name:String = graph!.names[id]!
        if name.utf16Count > maxStringLength {
            name = shortenFullName(name, NameDisplayMode.MiddleInitial)
        }
        if name.utf16Count > maxStringLength {
            name = shortenFullName(name, NameDisplayMode.LastInitialNoMiddle)
        }
        return name
    }

    /**
     * Notifies the graph that the user performed a match.
     */
    public func userDidMatch(firstId:UInt64, toSecondId:UInt64) {
        graph?.userDidMatch(firstId, toSecondId: toSecondId)
    }
    
    /**
     * Returns true iff the graph contains the given user id.
     */
    public func containsUser(userId:UInt64) -> Bool {
        return graph?.names[userId] != nil
    }
    
    /**
     * Returns the root user's id, or 0 if the graph has not
     * been initialized yet.
     */
    public func rootId() -> UInt64 {
        if graph == nil {
            return 0
        }
        return graph!.root
    }
    
    /**
     * Notify this controller that the graph was initialized,
     * whether it was using Core Data or Facebook statuses and
     * photos. This notifies the MatchViewController and the
     * MatchGraphController that the social graph has finished
     * loading and matches are ready to be presented.
     */
    public func didInitializeGraph() {
        delegate?.socialGraphControllerDidLoadSocialGraph(graph!)
        MatchGraphController.sharedInstance.socialGraphDidLoad()
        log("Initialized graph (\(graph!.names.count) nodes \(graph!.edgeCount) edges \(graph!.totalEdgeWeight) weight).", withIndent: 1)
        let timeString:String = String(format: "%.3f", currentTimeInSeconds() - SocialGraphController.sharedInstance.graphInitializeBeginTime)
        log("Time since startup: \(timeString) sec", withIndent: 1, withNewline: true)
        self.graph!.updateGenders()
        if doBuildGraphFromCoreData {
            didLoadVoteHistoryOrInitializeGraph()
        } else {
            graph!.updateGraphDataUsingPhotos()
        }
    }

    /**
     * Write the graph to core data. This includes information
     * for the root node, time modified, the edge list, and a
     * list of id-name mappings.
     */
    public func flushGraphToCoreData() {
        eraseGraphFromCoreData()
        managedObjectContext!.save(nil)
        log("Flushing the graph to core data...", withFlag: "!")
        RootData.insert(managedObjectContext!, rootId: graph!.root, timeModified: NSDate().timeIntervalSince1970)
        for (id:UInt64, name:String) in graph!.names {
            NodeData.insert(managedObjectContext!, nodeId: id, name: name)
        }
        for (node:UInt64, neighbors:[UInt64:Float]) in graph!.edges {
            for (neighbor:UInt64, weight:Float) in neighbors {
                if node < neighbor {
                    EdgeData.insert(managedObjectContext!, fromId: node, toId: neighbor, weight: weight)
                }
            }
        }
        var error:NSError? = nil
        managedObjectContext!.save(&error)
        if error != nil {
            log("Error when saving to Core Data: \(error!.description)")
        }
    }

    /**
     * Initializes the graph directly from core data.
     */
    private func initializeGraphFromCoreData(rootId:UInt64) {
        log("Initializing graph from core data...", withFlag:"!")
        var names:[UInt64:String] = [UInt64:String]()
        let nodes:[NodeData] = NodeData.allObjects(managedObjectContext!)
        for node in nodes {
            names[node.id()] = node.name
        }
        self.graph = SocialGraph(root: rootId, names: names)
        let edges:[EdgeData] = EdgeData.allObjects(managedObjectContext!)
        for edgeData:EdgeData in edges {
            graph!.connectNode(edgeData.from(), toNode: edgeData.to(), withWeight: edgeData.weight)
        }
        didInitializeGraph()
    }
    
    /**
     * Removes all graph data from local storage.
     */
    private func eraseGraphFromCoreData() {
        for root:RootData in RootData.allObjects(managedObjectContext!) {
            managedObjectContext!.deleteObject(root)
        }
        for node:NodeData in NodeData.allObjects(managedObjectContext!) {
            managedObjectContext!.deleteObject(node)
        }
        for edge:EdgeData in EdgeData.allObjects(managedObjectContext!) {
            managedObjectContext!.deleteObject(edge)
        }
    }

    /**
     * Determines whether or not we should use Core Data to
     * build the graph up.
     */
    private func shouldInitializeGraphFromCoreData(rootId:UInt64) -> Bool {
        if !kEnableGraphCaching {
            return false
        }
        let roots:[RootData] = RootData.allObjects(managedObjectContext!)
        if roots.count != 1 {
            return false
        }
        let secondsSinceUpdate:Double = NSDate().timeIntervalSince1970 - roots[0].timeModified
        return roots[0].id() == rootId && secondsSinceUpdate < kSecondsBeforeNextGraphUpdate
    }
}
