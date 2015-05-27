//
//  GraphBuildingUtilities.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 3/29/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import Parse

extension SocialGraph {

    /**
     * Queries the Facebook API for the user's friends, and uses the information to fetch
     * graph data from Parse. Only keeps one active request at a time, and makes a maximum
     * of maxNumFriends requests before stopping.
     */
    public func updateGraphDataFromFriends(maxNumFriends: Int = kMaxGraphDataQueries) {
        log("Fetching friends list...", withFlag: "!")
        let request: FBRequest = FBRequest.requestForMyFriends()
        request.startWithCompletionHandler{(connection: FBRequestConnection!, result: AnyObject!, error: NSError!) -> Void in
            if error == nil {
                var couplrFriends: [UInt64] = [UInt64]()
                if result["data"] == nil {
                    UserSessionTracker.sharedInstance.notify("Failed to fetch friends list!")
                    self.didFinishUpdatingFromFriendGraphs()
                    return
                }
                let friendsData: AnyObject! = result["data"]!
                for index in 0..<friendsData.count {
                    let friendObject: AnyObject! = friendsData[index]!
                    couplrFriends.append(uint64FromAnyObject(friendObject["id"]))
                }
                log("Found \(couplrFriends.count) friend(s).", withIndent: 1, withNewline: true)
                self.fetchAndUpdateGraphDataForFriends(&couplrFriends)
            }
        }
    }

    /**
     * Begins the graph initialization process, querying Facebook for
     * the user's posts. Upon a successful response, notifies the
     * match graph controller as well as the match view controller, and
     * also calls on the graph to request a gender update and query
     * Facebook again for comment likes.
     */
    public func updateGraphUsingPosts(minNumPosts: Int = kMinNumPosts, numQueriedPosts: Int = 0, var pagingURL: String? = nil) {
        if numQueriedPosts >= minNumPosts {
            log("The minimum number of posts have been queried", withFlag: "+", withIndent: 1)
            SocialGraphController.sharedInstance.didInitializeGraph()
            return
        }
        log("Requesting user posts...", withFlag: "!")
        if pagingURL == nil {
            pagingURL = "me/feed?limit=\(kMinNumPosts)&\(kPostGraphPathFields)"
        } else {
            pagingURL = pagingURL!.replace("\(kFBGraphURLPrefix)\(kFacebookAPIVersion)/", withString: "")
        }
        FBRequestConnection.startWithGraphPath(pagingURL!,
            completionHandler: { (connection, result, error) -> Void in
                if error == nil {
                    let postData: AnyObject! = result["data"]!
                    log("Analyzing \(postData.count) new posts...", withFlag: "+", withIndent: 1)
                    for index in 0..<postData.count {
                        let post: AnyObject! = postData[index]!
                        self.updateGraphUsingPost(post)
                    }
                    let paging: AnyObject? = result["paging"]
                    if paging != nil && paging!["next"] != nil {
                        let nextRequestURL: String = paging!["next"]! as! String
                        self.updateGraphUsingPosts(minNumPosts: minNumPosts, numQueriedPosts: numQueriedPosts + postData.count, pagingURL: nextRequestURL)
                    } else {
                        log("There are no new posts to fetch", withFlag: "+", withIndent: 1)
                        SocialGraphController.sharedInstance.didInitializeGraph()
                    }
                } else {
                    log("Critical error: \"\(error.description)\" when loading posts!", withFlag: "-", withNewline: true, withIndent: 1)
                    if numQueriedPosts > 0 {
                        log("Continuing graph initialization with incomplete data...", withFlag: "-", withIndent: 1)
                        SocialGraphController.sharedInstance.didInitializeGraph()
                    } else {
                        showLoginWithAlertViewErrorMessage("Try logging in again!", "Something went wrong.")
                    }
                }
            } as FBRequestHandler)
    }

    /**
     * Build the social graph using data from the user's photos.
     */
    public func updateGraphDataUsingPhotos(maxNumPhotos: Int = kMaxNumPhotos) {
        log("Requesting data from photos...", withFlag: "!")
        FBRequestConnection.startWithGraphPath("me/photos?limit=\(maxNumPhotos)&\(kPhotosGraphPathFields)",
            completionHandler: { (connection, result, error) -> Void in
                if error == nil {
                    let oldEdgeCount = self.edgeCount
                    let oldEdgeWeight = self.totalEdgeWeight
                    let oldVertexCount = self.nodes.count
                    var previousPhotoGroup: [UInt64: String] = [UInt64: String]()
                    
                    if let allPhotos: AnyObject? = result["data"] {
                        for index: Int in 0..<allPhotos!.count {
                            var photoGroup: [UInt64: String] = [UInt64: String]()
                            let photoData: AnyObject! = allPhotos![index]!
                            let (authorId: UInt64, authorName: String) = idAndNameFromObject(photoData["from"]!!)
                            // Build a dictionary of all the people in this photo.
                            photoGroup[authorId] = authorName
                            let photoTags: AnyObject? = photoData["tags"]
                            if photoTags == nil {
                                continue
                            }
                            let photoTagsData: AnyObject! = photoTags!["data"]!
                            for j: Int in 0..<photoTagsData.count {
                                let photoTag: AnyObject! = photoTagsData[j]
                                let (taggedId: UInt64, taggedName: String) = idAndNameFromObject(photoTag)
                                if taggedId != 0 {
                                    photoGroup[taggedId] = taggedName
                                }
                            }
                            if photoGroup.count <= 1 || photoGroup.count > kMaxPhotoGroupSize {
                                continue
                            }
                            let dissimilarity: Float = 1.0 - self.similarityOfGroups(photoGroup, second: previousPhotoGroup)
                            let pairwiseWeight: Float = dissimilarity * kMaxPairwisePhotoScore / Float(photoGroup.count - 1)
                            if pairwiseWeight >= kMinPhotoPairwiseWeight {
                                for (node: UInt64, name: String) in photoGroup {
                                    self.updateNodeWithId(node, andName: name, andUpdateGender: false)
                                }
                                // Create a fully connected clique using the tagged users.
                                for src: UInt64 in photoGroup.keys {
                                    for dst: UInt64 in photoGroup.keys {
                                        if src < dst {
                                            self.connectNode(src, toNode: dst, withWeight: pairwiseWeight)
                                        }
                                    }
                                }
                            }
                            previousPhotoGroup = photoGroup
                        }
                        log("Received \(allPhotos!.count) photos (+\(self.nodes.count - oldVertexCount) nodes, +\(self.edgeCount - oldEdgeCount) edges, +\(self.totalEdgeWeight - oldEdgeWeight) weight).", withIndent: 1, withNewline: true)
                    }
                    if self.nodes.count > 50 {
                        self.pruneGraphByMinWeightThreshold()
                        self.pruneGraphByIsolationFromRoot()
                    }
                    SocialGraphController.sharedInstance.flushGraphToCoreData()
                    SocialGraphController.sharedInstance.didLoadVoteHistoryOrInitializeGraph()
                } else {
                    log("Photos request failed with error \"\(error!.description)\"", withIndent: 1, withFlag: "-", withNewline: true)
                    showLoginWithAlertViewErrorMessage("Try logging in again.", "Something went wrong.")
                }
            } as FBRequestHandler)
    }
    
    /**
     * Makes a request to Parse for the graph rooted at the user given by id. If the graph
     * data exists, updates the graph using the new graph data, introducing new nodes and
     * edges and incrementing existing ones.
     */
    private func fetchAndUpdateGraphDataForFriends(inout idList: [UInt64], numFriendsQueried: Int = 0) {
        let id: UInt64 = popNextHighestConnectedFriend(&idList)
        if numFriendsQueried > kMaxGraphDataQueries || id == 0 {
            didFinishUpdatingFromFriendGraphs()
            return
        }
        log("Pulling the social graph of \(SocialGraphController.sharedInstance.nameFromId(id))...", withFlag: "!")
        var query: PFQuery = PFQuery(className: "GraphData")
        query.whereKey("rootId", equalTo: encodeBase64(id))
        query.findObjectsInBackgroundWithBlock({
            (objects: [AnyObject]!, error: NSError?) -> Void in
            if error != nil || objects.count < 1 {
                log("\(SocialGraphController.sharedInstance.nameFromId(id))'s graph was not found. Moving on...", withFlag: "?", withIndent: 1)
                self.fetchAndUpdateGraphDataForFriends(&idList, numFriendsQueried: numFriendsQueried)
                return
            }
            let graphData: AnyObject! = objects[0]
            let newNamesObject: AnyObject! = graphData["names"]
            var newNames: [UInt64: String] = [UInt64: String]()
            for nodeAsObject: AnyObject in newNamesObject.allKeys {
                let node: UInt64 = uint64FromAnyObject(nodeAsObject, base64: true)
                newNames[node] = newNamesObject[nodeAsObject.description] as? String
            }
            let newEdges: AnyObject! = graphData["edges"]
            // Parse incoming graph's edges into a dictionary for fast lookup.
            var newEdgeMap: [UInt64: [UInt64: Float]] = [UInt64: [UInt64: Float]]()
            for index in 0..<newEdges.count {
                let edge: AnyObject! = newEdges[index]!
                let src: UInt64 = uint64FromAnyObject(edge[0], base64: true)
                let dst: UInt64 = uint64FromAnyObject(edge[1], base64: true)
                let weight: Float = floatFromAnyObject(edge[2])
                if newEdgeMap[src] == nil {
                    newEdgeMap[src] = [UInt64: Float]()
                }
                if newEdgeMap[dst] == nil {
                    newEdgeMap[dst] = [UInt64: Float]()
                }
                newEdgeMap[src]![dst] = weight
                newEdgeMap[dst]![src] = weight
            }
            var newNodeList: [UInt64] = [UInt64]()
            // Use new edges to determine whether each new node should be added to the graph.
            for (node: UInt64, name: String) in newNames {
                if self.nodes[node] != nil {
                    continue
                }
                // Check whether the node has enough neighbors in the current social network.
                let neighbors: [UInt64: Float] = newEdgeMap[node]!
                var mutualFriendCount: Int = 0
                for (neighbor: UInt64, weight: Float) in neighbors {
                    if self.nodes[neighbor] != nil {
                        mutualFriendCount++
                    }
                }
                if mutualFriendCount >= kMutualFriendsThreshold {
                    newNodeList.append(node)
                }
            }
            // Update the graph to contain all the new nodes.
            for newNode: UInt64 in newNodeList {
                self.updateNodeWithId(newNode, andName: newNames[newNode]!)
            }
            // Add all new edges that connect two members of the original graph.
            var edgeUpdateCount: Int = 0
            for (node: UInt64, neighbors: [UInt64: Float]) in newEdgeMap {
                for (neighbor: UInt64, weight: Float) in neighbors {
                    if node < neighbor && self.nodes[node] != nil && self.nodes[neighbor] != nil {
                        self.connectNode(node, toNode: neighbor, withWeight: weight)
                        edgeUpdateCount++
                    }
                }
            }
            log("Finished updating graph for root id \(SocialGraphController.sharedInstance.nameFromId(id)).", withIndent: 1)
            log("\(newNodeList.count) nodes added; \(edgeUpdateCount) edges updated.", withIndent: 1, withNewline: true)
            self.fetchAndUpdateGraphDataForFriends(&idList, numFriendsQueried: numFriendsQueried + 1)
        })
    }

    /**
     * Helper method that updates this graph given data for one Facebook post.
     */
    private func updateGraphUsingPost(post: AnyObject!) -> Void {
        var allComments: AnyObject? = post["comments"]
        var previousCommentAuthorId: UInt64 = root;
        if allComments != nil {
            let commentData: AnyObject! = allComments!["data"]!
            for index in 0..<commentData.count {
                let comment: AnyObject! = commentData[index]!
                // Add scores for the author of the comment.
                let from: AnyObject? = comment["from"]
                if from == nil {
                    continue
                }
                let fromId: UInt64 = uint64FromAnyObject(from!["id"]!)
                let fromNameObject: AnyObject! = from!["name"]!
                updateNodeWithId(fromId, andName: fromNameObject.description!)
                connectNode(root, toNode: fromId, withWeight: kCommentRootScore)
                connectNode(previousCommentAuthorId, toNode: fromId, withWeight: kCommentPrevScore)
                previousCommentAuthorId = fromId
                // Add comment like data if it exists.
                let commentLikes: AnyObject? = comment["likes"]
                if commentLikes == nil {
                    continue
                }
                let commentLikeData: AnyObject! = commentLikes!["data"]!
                for index in 0..<commentLikeData.count {
                    let commentLike: AnyObject! = commentLikeData[index]
                    let commentLikeId: UInt64 = uint64FromAnyObject(commentLike["id"])
                    let commentLikeNameObject: AnyObject! = commentLike["name"]!
                    let commentLikeName: String = commentLikeNameObject.description
                    updateNodeWithId(commentLikeId, andName: commentLikeName)
                    connectNode(commentLikeId, toNode: fromId, withWeight: kCommentLikeScore)
                }
            }
        }
        var allLikes: AnyObject? = post["likes"]
        if allLikes != nil {
            if let likeData: AnyObject? = allLikes!["data"] {
                for index in 0..<likeData!.count {
                    let like: AnyObject! = likeData![index]!
                    let fromId: UInt64 = uint64FromAnyObject(like["id"]!)
                    let fromNameObject: AnyObject! = like["name"]
                    updateNodeWithId(fromId, andName: fromNameObject.description!)
                    connectNode(root, toNode: fromId, withWeight: kLikeRootScore)
                }
            }
        }
    }
    
    /**
     * Invoked when data from friends' social networks has been added
     * to the graph. didPerformUpdate indicates whether fetching friend
     * graph information caused an error.
     */
    private func didFinishUpdatingFromFriendGraphs() {
        log("Done. No more friends to query.", withIndent: 1)
        let timeString: String = String(format: "%.3f", currentTimeInSeconds() - SocialGraphController.sharedInstance.graphInitializeBeginTime)
        log("Time since startup: \(timeString) sec", withIndent: 2, withNewline: true)
        updateGenders()
        if kUseMedianAsWeightBaseline {
            updateMedianEdgeWeight()
        }
        log("Vertex count: \(nodes.count)", withIndent: 1)
        log("Edge count: \(edgeCount)", withIndent: 1)
        log("Total weight: \(totalEdgeWeight)", withIndent: 1)
        log("Weight baseline: \(baselineEdgeWeight())", withIndent: 1)
        MatchGraphController.sharedInstance.didFinishLoadingExtendedSocialGraph()
    }

    /**
     * Computes how "similar" two groups of users are. Returns a
     * float between 0 and 1, inclusive.
     */
    private func similarityOfGroups(first: [UInt64: String], second: [UInt64: String], andIgnoreRoot: Bool = true) -> Float {
        var similarityCount: Float = 0
        var totalCount: Float = 0
        for node: UInt64 in first.keys {
            if andIgnoreRoot && node == root {
                continue
            }
            if second[node] != nil {
                similarityCount++
            }
            totalCount++
        }
        for node: UInt64 in second.keys {
            if andIgnoreRoot && node == root {
                continue
            }
            if first[node] != nil {
                similarityCount++
            }
            totalCount++
        }
        if totalCount == 0 {
            return 1
        }
        return similarityCount / totalCount
    }

    /**
     * Given a list of friends, pops off the next highest connected friend and
     * returns the friend's id.
     */
    private func popNextHighestConnectedFriend(inout friendList: [UInt64]) -> UInt64 {
        if friendList.count == 0 {
            return 0
        }
        var maxFriendWeight: Float = -Float.infinity
        var nextFriend: UInt64 = 0
        var maxFriendIndex: Int = 0
        for index: Int in 0..<friendList.count {
            let friend: UInt64 = friendList[index]
            var friendWeight: Float;
            if self.nodes[friend] == nil {
                friendWeight = -1
            } else {
                friendWeight = self[self.root, friend]
                if friendWeight < kUnconnectedEdgeWeight {
                    friendWeight = 0
                }
            }
            if friendWeight > maxFriendWeight {
                maxFriendWeight = friendWeight
                nextFriend = friend
                maxFriendIndex = index
            }
        }
        friendList.removeAtIndex(maxFriendIndex)
        return nextFriend
    }
}
