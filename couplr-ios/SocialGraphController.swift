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
    
    class var sharedInstance: SocialGraphController {
        struct SocialGraphSingleton {
            static let instance = SocialGraphController()
        }
        return SocialGraphSingleton.instance
    }
    
    public func initializeGraph() {
        log("Requesting user statuses...", withFlag:"!")
        FBRequestConnection.startWithGraphPath(
            "me/statuses?limit=100",
            completionHandler: { (connection, result, error) -> Void in
                if error == nil {
                    let statusData:AnyObject! = result["data"]!
                    let statusCount:Int = statusData.count
                    let firstStatusFromObject:AnyObject! = statusData[0]!["from"]!
                    let firstStatusFromObjectName:AnyObject! = firstStatusFromObject["name"]!
                    let rootUserID:UInt64! = uint64FromAnyObject(firstStatusFromObject["id"]!)
                    let rootUserName:String! = firstStatusFromObjectName.description!
                    var builder:GraphBuilder = GraphBuilder(forRootUserID:rootUserID, withName: rootUserName)
                    for index in 0..<statusCount {
                        let status:AnyObject! = statusData[index]!
                        self.updateFromStatus(status, withRootID: rootUserID, withBuilder: &builder)
                    }
                    let graph:SocialGraph = builder.buildSocialGraph()
                    self.graph = graph
                    self.delegate?.socialGraphControllerDidLoadSocialGraph(graph)
                    MatchGraphController.sharedInstance.socialGraphDidLoad()
                    log("Initialized base graph (\(graph.names.count) nodes \(graph.edgeCount) edges) from \(statusCount) comments.", withIndent:1)
                    self.graph?.updateGenders()
                    self.graph?.updateCommentLikes(builder.commentsWithLikesForAuthor, andSaveGraphData:true)
                }
            } as FBRequestHandler
        )
    }
    
    private func updateFromStatus(status:AnyObject!, withRootID:UInt64!, inout withBuilder:GraphBuilder) -> Void {
        var allComments:AnyObject? = status["comments"]
        var previousThreadID:UInt64 = withRootID;
        if allComments != nil {
            let commentData:AnyObject! = allComments!["data"]!
            for index in 0..<commentData.count {
                let comment:AnyObject! = commentData[index]!
                // Add scores for the author of the comment.
                let from:AnyObject! = comment["from"]!
                let fromID:UInt64 = uint64FromAnyObject(from["id"]!)
                let fromNameObject:AnyObject! = from["name"]!
                withBuilder.updateNameMappingForID(fromID, toName: fromNameObject.description!)
                withBuilder.updateForEdgePair(EdgePair(first:withRootID, second:fromID), withWeight:kCommentRootScore)
                withBuilder.updateForEdgePair(EdgePair(first:previousThreadID, second:fromID), withWeight:kCommentPrevScore)
                // Check if the comment has any likes.
                if let commentIDObject:AnyObject? = comment["id"] {
                    if uint64FromAnyObject(comment["like_count"]!) > 0 {
                        withBuilder.updateCommentsWithLikes(commentIDObject!.description!, forAuthorID:fromID)
                    }
                }
                previousThreadID = fromID
            }
        }
        var allLikes:AnyObject? = status["likes"]
        if allLikes != nil {
            let likeData:AnyObject! = allLikes!["data"]!
            for index in 0..<likeData.count {
                let like:AnyObject! = likeData[index]!
                let fromID:UInt64 = uint64FromAnyObject(like["id"]!)
                let fromNameObject:AnyObject! = like["name"]
                withBuilder.updateNameMappingForID(fromID, toName: fromNameObject.description!)
                withBuilder.updateForEdgePair(EdgePair(first:withRootID, second:fromID), withWeight: kLikeRootScore)
            }
        }
    }
}
