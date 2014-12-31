//
//  UtilityFunctions.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/28/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit
import Dispatch

func afterDelay(seconds: Double, closure: () -> ()) {
    let when = dispatch_time(DISPATCH_TIME_NOW, Int64(seconds * Double(NSEC_PER_SEC)))
    dispatch_after(when, dispatch_get_main_queue(), closure)
}

func randomFloat() -> Float {
    return Float(arc4random()) / Float(UINT32_MAX)
}

/**
 * Returns a random positive integer LESS THAN a given upper
 * bound.
 */
func randomInt(withUpperbound:Int) -> Int {
    return Int(floorf(randomFloat() * (Float(withUpperbound))))
}

/**
 * Returns a randomly sampled node given a list of sampling weights. If
 * the list elements to sample is empty, returns a default value of 0.
 * TODO This is a naive implementation. Make me faster!
 */
func weightedRandomSample(elements:[(UInt64, Float)]) -> UInt64 {
    if elements.count == 0 {
        return 0
    }
    var total:Float = 0
    for (node:UInt64, value:Float) in elements {
        total += value
    }
    var sampleTarget:Float = total * randomFloat()
    var (result:UInt64, temp:Float) = elements[0]
    for index:Int in 0..<elements.count {
        let (node:UInt64, value:Float) = elements[index]
        result = node
        sampleTarget -= value
        if sampleTarget <= 0 {
            break
        }
    }
    return result
}

func appendEdgesFromStatus(status:AnyObject!, withRootID:UInt64!, inout toBuilder:GraphBuilder) -> Void {
    var allComments:AnyObject? = status["comments"]
    var previousThreadID:UInt64 = withRootID;
    if allComments != nil {
        let commentData:AnyObject! = allComments!["data"]!
        for index in 0..<commentData.count {
            let comment:AnyObject! = commentData[index]!
            let from:AnyObject! = comment["from"]!
            let fromIDObject:AnyObject! = from["id"]!
            let fromID:UInt64 = UInt64(fromIDObject.description!.toInt()!)
            let fromNameObject:AnyObject! = from["name"]
            toBuilder.updateNameMappingForID(fromID, toName: fromNameObject.description!)
            toBuilder.updateForEdgePair(EdgePair(first:withRootID, second:fromID), withWeight:kCommentRootScore)
            toBuilder.updateForEdgePair(EdgePair(first:previousThreadID, second:fromID), withWeight:kCommentPrevScore)
            previousThreadID = fromID
        }
    }
    var allLikes:AnyObject? = status["likes"]
    if allLikes != nil {
        let likeData:AnyObject! = allLikes!["data"]!
        for index in 0..<likeData.count {
            let like:AnyObject! = likeData[index]!
            let fromIDObject:AnyObject! = like["id"]!
            let fromID:UInt64 = UInt64(fromIDObject.description!.toInt()!)
            let fromNameObject:AnyObject! = like["name"]
            toBuilder.updateNameMappingForID(fromID, toName: fromNameObject.description!)
            toBuilder.updateForEdgePair(EdgePair(first:withRootID, second:fromID), withWeight: kLikeRootScore)
        }
    }
}

func edgeListFromStatusesForRootUser() {
    FBRequestConnection.startWithGraphPath(
        "me/statuses?limit=100",
        completionHandler: { (connection, result, error) -> Void in
            if error == nil {
                let statusData:AnyObject! = result["data"]!
                let statusCount:Int = statusData.count
                let firstStatusFromObject:AnyObject! = statusData[0]!["from"]!
                let firstStatusFromObjectID:AnyObject! = firstStatusFromObject["id"]!
                let firstStatusFromObjectName:AnyObject! = firstStatusFromObject["name"]!
                let firstStatusFromObjectIDAsInt:UInt64! = UInt64(firstStatusFromObjectID.description!.toInt()!)
                let firstStatusFromObjectNameAsString:String! = firstStatusFromObjectName.description!
                var builder:GraphBuilder = GraphBuilder()
                builder.updateNameMappingForID(firstStatusFromObjectIDAsInt, toName: firstStatusFromObjectNameAsString)
                builder.updateRootUserID(firstStatusFromObjectIDAsInt)
                for index in 0..<statusCount {
                    let status:AnyObject! = statusData[index]!
                    appendEdgesFromStatus(status, firstStatusFromObjectIDAsInt, &builder)
                }
                let graph:SocialGraph = builder.buildSocialGraph()
                println(graph.toString())
                println(graph.randomSample())
            }
        } as FBRequestHandler
    )
}
