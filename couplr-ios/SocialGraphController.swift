//
//  SocialGraphController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/30/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

protocol SocialGraphControllerDelegate: class {
    func socialGraphControllerDidLoadSocialGraph(graph: SocialGraph)
}

public class SocialGraphController {

    weak var delegate: SocialGraphControllerDelegate?
    var graph: SocialGraph?
    var voteHistoryOrPhotoDataLoadProgress:Int = 0
    var graphSerializationSemaphore = dispatch_semaphore_create(1)

    class var sharedInstance: SocialGraphController {
        struct SocialGraphSingleton {
            static let instance = SocialGraphController()
        }
        return SocialGraphSingleton.instance
    }

    /**
     * Begins the graph initialization process, querying Facebook for
     * the user's statuses. Upon a successful response, notifies the
     * match graph controller as well as the match view controller, and
     * also calls on the graph to request a gender update and query
     * Facebook again for comment likes.
     */
    public func initializeGraph(maxNumStatuses:Int = kMaxNumStatuses) {
        log("Requesting user statuses...", withFlag:"!")
        FBRequestConnection.startWithGraphPath("me/statuses?limit=\(maxNumStatuses)&fields=from,likes,comments.fields(from,likes)",
            completionHandler: { (connection, result, error) -> Void in
                if error == nil {
                    let statusData:AnyObject! = result["data"]!
                    let statusCount:Int = statusData.count
                    let firstStatusFromObject:AnyObject! = statusData[0]!["from"]!
                    let firstStatusFromObjectName:AnyObject! = firstStatusFromObject["name"]!
                    let rootUserId:UInt64! = uint64FromAnyObject(firstStatusFromObject["id"]!)
                    let rootUserName:String! = firstStatusFromObjectName.description!
                    var builder:GraphBuilder = GraphBuilder(forRootUserId:rootUserId, withName:rootUserName)
                    for index in 0..<statusCount {
                        let status:AnyObject! = statusData[index]!
                        self.updateGraphBuilderFromStatus(status, withRootId:rootUserId, withBuilder:&builder)
                    }
                    let graph:SocialGraph = builder.buildSocialGraph()
                    self.graph = graph
                    self.delegate?.socialGraphControllerDidLoadSocialGraph(graph)
                    MatchGraphController.sharedInstance.socialGraphDidLoad()
                    log("Initialized base graph (\(graph.names.count) nodes \(graph.edgeCount) edges \(graph.totalEdgeWeight) weight) from \(statusCount) statuses.", withIndent:1, withNewline:true)
                    self.graph!.updateGenders()
                    self.graph!.updateGraphDataUsingPhotos()
                } else {
                    log("Critical error: \"\(error.description)\" when loading comments!", withFlag:"-", withNewline:true)
                }
        } as FBRequestHandler)
    }
    
    /**
     * Notifies this controller that the match graph finished loading
     * the root user's match history. When both the vote history and
     * photo data are loaded, adds edges from the user's matches to
     * the graph and exports the results to Parse.
     */
    public func didLoadVoteHistoryOrPhotoData() {
        dispatch_semaphore_wait(graphSerializationSemaphore, DISPATCH_TIME_FOREVER)
        voteHistoryOrPhotoDataLoadProgress++
        if voteHistoryOrPhotoDataLoadProgress == 2 {
            // Both vote history and photo data are finished loading.
            let voteHistory:[(UInt64, UInt64, Int)] = MatchGraphController.sharedInstance.matches!.userVoteHistory
            for (firstId:UInt64, secondId:UInt64, titleId:Int) in voteHistory {
                // For each match the user makes, connect the matched nodes.
                if graph!.names[firstId] != nil && graph!.names[secondId] != nil {
                    graph!.connectNode(firstId, toNode:secondId, withWeight:kUserMatchVoteScore)
                }
            }
            graph!.saveGraphData(andLoadFriendGraphs:true)
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
            name = shortenFullName(name, true, false)
        }
        if name.utf16Count > maxStringLength {
            name = shortenFullName(name, true, true)
        }
        return name
    }

    /**
     * Notifies the graph that the user performed a match.
     */
    public func userDidMatch(firstId:UInt64, toSecondId:UInt64) {
        graph?.userDidMatch(firstId, toSecondId:toSecondId)
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

    private func updateGraphBuilderFromStatus(status:AnyObject!, withRootId:UInt64!, inout withBuilder:GraphBuilder) -> Void {
        var allComments:AnyObject? = status["comments"]
        var previousThreadId:UInt64 = withRootId;
        if allComments != nil {
            let commentData:AnyObject! = allComments!["data"]!
            for index in 0..<commentData.count {
                let comment:AnyObject! = commentData[index]!
                // Add scores for the author of the comment.
                let from:AnyObject! = comment["from"]!
                let fromId:UInt64 = uint64FromAnyObject(from["id"]!)
                let fromNameObject:AnyObject! = from["name"]!
                withBuilder.updateNameMappingForId(fromId, toName: fromNameObject.description!)
                withBuilder.updateForEdgePair(EdgePair(first:withRootId, second:fromId), withWeight:kCommentRootScore)
                withBuilder.updateForEdgePair(EdgePair(first:previousThreadId, second:fromId), withWeight:kCommentPrevScore)
                previousThreadId = fromId
                // Add comment like data if it exists.
                let commentLikes:AnyObject? = comment["likes"]
                if commentLikes == nil {
                    continue
                }
                let commentLikeData:AnyObject! = commentLikes!["data"]!
                for index in 0..<commentLikeData.count {
                    let commentLike:AnyObject! = commentLikeData[index]
                    let commentLikeId:UInt64 = uint64FromAnyObject(commentLike["id"])
                    let commentLikeNameObject:AnyObject! = commentLike["name"]!
                    let commentLikeName:String = commentLikeNameObject.description
                    withBuilder.updateNameMappingForId(commentLikeId, toName:commentLikeName)
                    withBuilder.updateForEdgePair(EdgePair(first:commentLikeId, second:fromId), withWeight:kCommentLikeScore)
                }
            }
        }
        var allLikes:AnyObject? = status["likes"]
        if allLikes != nil {
            let likeData:AnyObject! = allLikes!["data"]!
            for index in 0..<likeData.count {
                let like:AnyObject! = likeData[index]!
                let fromId:UInt64 = uint64FromAnyObject(like["id"]!)
                let fromNameObject:AnyObject! = like["name"]
                withBuilder.updateNameMappingForId(fromId, toName: fromNameObject.description!)
                withBuilder.updateForEdgePair(EdgePair(first:withRootId, second:fromId), withWeight:kLikeRootScore)
            }
        }
    }
}
