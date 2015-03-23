//
//  SocialGraph.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 12/26/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import Parse
import CoreData

// MARK: - Social graph parameters
let kUnconnectedEdgeWeight:Float = -1000.0          // The weight of an unconnected "edge".
let kMaxNumStatuses:Int = 100                       // Number of statuses to query.
let kMaxNumPhotos:Int = 100                         // Number of photos to query.
let kMaxPhotoGroupSize:Int = 15                     // Max number of people considered in a photo.
let kMinGraphEdgeWeight:Float = 0.15                // The minimum edge weight threshold when cleaning the graph.
let kUserMatchVoteScore:Float = 1.0                 // Score for the user voting on title for a match.
// Like and comment scores.
let kCommentRootScore:Float = 0.5                   // Score for commenting on the root user's status.
let kCommentPrevScore:Float = 0.1                   // Score for being the next to comment on the root user's status.
let kLikeRootScore:Float = 0.2                      // Score for a like on the root user's status.
let kCommentLikeScore:Float = 0.4                   // Score for a like on someone's comment on the root user's status.
// Constants for scoring photo data.
let kMaxPairwisePhotoScore:Float = 1.5              // A base photo score for a picture containing only 2 people.
let kMinPhotoPairwiseWeight:Float = 0.05            // Only add edges from photo data with at least this weight.

let kSamplingWeightLimit:Float = 10                 // The coefficient for the sigmoid function.
let kSigmoidExponentialBase:Float = 3.5             // The exponential base for the sigmoid function.
let kRandomSampleCount:Int = 9                      // The number of people to randomly sample.

let kMaxGraphDataQueries:Int = 4                    // Max number of friends to query graph data from.
let kMinExportEdgeWeight:Float = 0.2                // Only export edges with more than this weight.
let kScaleFactorForExportingRootEdges:Float = 0.25  // Export root edges scaled by this number.
let kMutualFriendsThreshold:Int = 3                 // This many mutual friends to pull a friend over to the user's graph.

let kGenderBiasRatio:Float = 4.0                    // Make it this much more likely to land on the opposite gender.
let kWalkWeightUserMatchBoost:Float = 1.5           // The walk weight "bonus" for a node when the user selects a match.
let kWalkWeightDecayRate:Float = 0.5                // The decay rate for the walk weight bonus.
let kWalkWeightPenalty:Float = 0.5                  // Constant penalty per step to encourage choosing new nodes.

// MARK: - Gender enum

/**
 * It's not quite politically correct, but it's a start.
 * TODO Better support for non-heteronormativity.
 */
public enum Gender {
    case Male, Female, Undetermined
    public func toString() -> String {
        switch self {
        case .Male:
            return "male"
        case .Female:
            return "female"
        case .Undetermined:
            return "undetermined"
        }
    }

    /**
     * Maps "male" to Gender.Male, "female" to Gender.Female, and anything
     * else to Undetermined.
     */
    static func fromString(gender:String) -> Gender {
        let lowercaseGender:String = gender.lowercaseString
        if lowercaseGender == "1" || lowercaseGender == "female" {
            return Gender.Female
        } else if lowercaseGender == "0" || lowercaseGender == "male" {
            return Gender.Male
        }
        return Gender.Undetermined
    }
}

// SocialGraph class

/**
 * Represents a user's social graph derived from scraping Facebook data.
 */
public class SocialGraph {

    /**
     * Initializes an empty graph rooted at a given user with a mapping from
     * user ID.
     */
    public init(root:UInt64, names:[UInt64:String]) {
        self.root = root
        self.names = names
        self.edges = [UInt64:[UInt64:Float]]()
        self.totalEdgeWeight = 0
        self.edgeCount = 0
        self.totalEdgeWeightFromRoot = 0
        self.genders = [String:Gender]()
        self.isCurrentlyUpdatingGender = false
        self.shouldReupdateGender = false
        self.didLoadGendersFromCache = false
        self.walkWeightMultipliers = [UInt64:Float]()
        self.currentSample = [UInt64]()
    }

    /**
     * Returns a string representation of this graph, displaying its edges.
     */
    public func toString() -> String {
        var out:String = "SocialGraph({\n"
        out += "    node count   : \(self.names.count)\n"
        out += "    edge count   : \(edgeCount)\n"
        out += "    total weight : \(totalEdgeWeight)\n\n"
        for (node, neighbors) in edges {
            var nodeName:String = names[node] != nil ? names[node]! : String(node)
            out += "    \(nodeName) = [\n"
            for (neighbor, weight) in neighbors {
                var neighborName:String = (names[neighbor] != nil) ? names[neighbor]! : String(neighbor)
                out += "        (\(nodeName) -> \(neighborName)) = \(weight),\n"
            }
            out += "    ]\n"
        }
        out += "})"
        return out
    }

    // MARK: - Graph topology modifiers

    /**
     * Update the graph with a new node and name. Adds the new node to the name
     * mapping if it does not already appear. Also adds the first name to the
     * gender mapping if the first name does not already appear, with an initial
     * value of Gender.Undetermined.
     */
    public func updateNodeWithId(id:UInt64, andName:String, andUpdateGender:Bool = true) {
        if names[id] == nil {
            names[id] = andName
            let firstName:String = firstNameFromFullName(andName)
            if andUpdateGender {
                if genders[firstName] == nil {
                    genders[firstName] = Gender.Undetermined
                }
            }
        }
    }

    /**
     * Adds an undirected edge between two users, implemented as two directed
     * edges in reverse directions. Using connectNode to modify the graph will
     * enforce symmetry.
     */
    public func connectNode(node:UInt64, toNode:UInt64, withWeight:Float = 1) {
        medianEdgeWeight = nil
        if !hasEdgeFromNode(node, to: toNode) {
            edgeCount++
        }
        totalEdgeWeight += withWeight
        if node == root || toNode == root {
            totalEdgeWeightFromRoot += withWeight
        }
        addEdgeFrom(node, toNode: toNode, withWeight: withWeight)
        addEdgeFrom(toNode, toNode: node, withWeight: withWeight)
    }

    /**
     * Removes all edges between two users. Using disconnectNode to modify the
     * graph will enforce symmetry.
     */
    public func disconnectNode(node:UInt64, fromNode:UInt64) {
        let currentEdgeWeight:Float = self[node, fromNode]
        if currentEdgeWeight > kUnconnectedEdgeWeight {
            medianEdgeWeight = nil
            edgeCount--
            totalEdgeWeight -= currentEdgeWeight
            if node == root || fromNode == root {
                totalEdgeWeightFromRoot -= currentEdgeWeight
            }
            removeEdgeFrom(node, toNode: fromNode)
            removeEdgeFrom(fromNode, toNode: node)
        }
    }

    /**
     * Returns whether or not two nodes are connected. Assumes that all edges are undirected.
     */
    public func hasEdgeFromNode(node:UInt64, to:UInt64) -> Bool {
        return self[node, to] > kUnconnectedEdgeWeight
    }
    
    /**
     * Returns the connection weight between two given nodes.
     */
    public subscript(node:UInt64, toNode:UInt64) -> Float {
        return weightFrom(node, toNode: toNode)
    }

    /**
     * Adds a directed edge with specified weight between two users. Does
     * not check for self-edges. If an edge already exists between the users,
     * increments the current weight of the edge.
     * In general, you should not be adding directed edges to the social graph.
     * Instead, use connectNode to update the graph.
     */
    private func addEdgeFrom(node:UInt64, toNode:UInt64, withWeight:Float = 1) {
        if edges[node] == nil {
            edges[node] = [UInt64:Float]()
        }
        var currentWeight:Float = weightFrom(node, toNode: toNode)
        if currentWeight <= kUnconnectedEdgeWeight {
            currentWeight = 0
        }
        edges[node]![toNode] = currentWeight + withWeight
    }

    /**
     * Removes an edge connecting one node to another, if any. In general,
     * you should not be removing directed edges from the social graph.
     * Instead, use disconnectNode to update the graph.
     */
    private func removeEdgeFrom(node:UInt64, toNode:UInt64) {
        if edges[node] != nil && edges[node]![toNode] != nil {
            edges[node]![toNode] = nil
            if edges[node]!.count == 0 {
                edges[node] = nil
            }
        }
    }

    /**
     * Returns the connection weight between two given nodes.
     */
    private func weightFrom(node:UInt64, toNode:UInt64) -> Float {
        return (edges[node] == nil || edges[node]![toNode] == nil) ? kUnconnectedEdgeWeight : edges[node]![toNode]!
    }

    /**
     * Iterate through all edges in the graph and remove edges
     * that have a weight less than a minimum threshold.
     */
    private func pruneGraphByMinWeightThreshold(minWeight:Float = kMinGraphEdgeWeight) {
        // Collect a list of undirected edges that should be removed.
        var edgesToRemove:[(UInt64, UInt64)] = []
        for (node:UInt64, neighbors:[UInt64:Float]) in edges {
            for (neighbor:UInt64, weight:Float) in edges[node]! {
                if node < neighbor && weight < kMinGraphEdgeWeight {
                    edgesToRemove.append((node, neighbor))
                }
            }
        }
        // Remove the undirected edges.
        for (src:UInt64, dst:UInt64) in edgesToRemove {
            disconnectNode(src, fromNode: dst)
        }
        // Remove fully disconnected nodes.
        var nodesToRemove:[UInt64] = []
        for node:UInt64 in names.keys {
            if edges[node] == nil {
                nodesToRemove.append(node)
            }
        }
        for node:UInt64 in nodesToRemove {
            names[node] = nil
        }
    }

    // MARK: - Asynchronous update functions and subroutines

    /**
     * Load a map from first name to gender using the first names encountered
     * in the graph. Sends a request for each first name for which gender is
     * currently unknown. Initially, the gender dictionary maps all first names
     * to Gender.Undetermined.
     *
     * If another gender update is currently taking place when this function is
     * invoked, it will wait until the first response is received before executing.
     * Additionally, if this function is invoked more than 2 times before the first
     * response is received, only the second call will "go through" -- all
     * subsequent invocations will be dropped.
     */
    public func updateGenders() {
        dispatch_semaphore_wait(genderUpdateSemaphore, DISPATCH_TIME_FOREVER)
        if isCurrentlyUpdatingGender {
            shouldReupdateGender = true
            return
        }
        isCurrentlyUpdatingGender = true
        dispatch_semaphore_signal(genderUpdateSemaphore)
        log("Requesting gender update...", withFlag: "!")
        updateFirstNames()
        if !didLoadGendersFromCache {
            let cachedGenders:[GenderData] = GenderData.allObjects(SocialGraphController.sharedInstance.managedObjectContext!)
            for genderData in cachedGenders {
                self.genders[genderData.firstName] = genderData.gender()
            }
            didLoadGendersFromCache = true
        }
        let addGenders:(NSData?, NSURLResponse?, NSError?) -> Void = {
            (data:NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil {
                var error:NSError? = nil
                let rawGenderData:AnyObject = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(0), error: &error)!
                if let genderData = rawGenderData as? [String : AnyObject] {
                    for (firstName:String, genderIndicator:AnyObject) in genderData {
                        let gender = Gender.fromString(genderIndicator.description!)
                        self.genders[firstName] = gender
                        if gender != Gender.Undetermined {
                            GenderData.insert(SocialGraphController.sharedInstance.managedObjectContext!, name: firstName, gender: gender)
                        }
                    }
                    SocialGraphController.sharedInstance.managedObjectContext!.save(nil)
                    let (males:Int, females:Int, undetermined:Int) = self.overallGenderCount()
                    log("Gender response received (\(genderData.count) predictions).", withIndent: 1)
                    log("Current breakdown: \(males) males, \(females) females, \(undetermined) undetermined.", withIndent: 1, withNewline: true)
                }
            }
            self.isCurrentlyUpdatingGender = false
            if self.shouldReupdateGender {
                self.shouldReupdateGender = false
                self.updateGenders()
            }
        }
        var requestURL:String = kGenderizeURLPrefix
        for (firstName:String, gender:Gender) in genders {
            if gender == Gender.Undetermined {
                requestURL += "\(firstName),"
            }
        }
        if genders.count > 0 {
            requestURL = requestURL.substringToIndex(requestURL.endIndex.predecessor()) // Remove the trailing ampersand.
            getRequestToURL(requestURL, addGenders)
        }
    }

    /**
     * Queries the Facebook API for the user's friends, and uses the information to fetch
     * graph data from Parse. Only keeps one active request at a time, and makes a maximum
     * of maxNumFriends requests before stopping.
     */
    public func updateGraphDataFromFriends(maxNumFriends:Int = kMaxGraphDataQueries) {
        log("Fetching friends list...", withFlag: "!")
        let request:FBRequest = FBRequest.requestForMyFriends()
        request.startWithCompletionHandler{(connection:FBRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if error == nil {
                var couplrFriends:[UInt64] = [UInt64]()
                let friendsData:AnyObject! = result["data"]!
                for index in 0..<friendsData.count {
                    let friendObject:AnyObject! = friendsData[index]!
                    couplrFriends.append(uint64FromAnyObject(friendObject["id"]))
                }
                log("Found \(couplrFriends.count) friend(s).", withIndent: 1, withNewline: true)
                self.fetchAndUpdateGraphDataForFriends(&couplrFriends)
            }
        }
    }
    
    /**
     * Begins the graph initialization process, querying Facebook for
     * the user's statuses. Upon a successful response, notifies the
     * match graph controller as well as the match view controller, and
     * also calls on the graph to request a gender update and query
     * Facebook again for comment likes.
     */
    public func updateGraphUsingStatuses(maxNumStatuses:Int = kMaxNumStatuses) {
        log("Requesting user statuses...", withFlag: "!")
        FBRequestConnection.startWithGraphPath("me/statuses?limit=\(maxNumStatuses)&\(kStatusGraphPathFields)",
            completionHandler: { (connection, result, error) -> Void in
                if error == nil {
                    let statusData:AnyObject! = result["data"]!
                    for index in 0..<statusData.count {
                        let status:AnyObject! = statusData[index]!
                        self.updateGraphUsingStatus(status)
                    }
                    SocialGraphController.sharedInstance.didInitializeGraph()
                } else {
                    log("Critical error: \"\(error.description)\" when loading statuses!", withFlag: "-", withNewline: true)
                }
        } as FBRequestHandler)
    }
    
    /**
    * Build the social graph using data from the user's photos.
    */
    public func updateGraphDataUsingPhotos(maxNumPhotos:Int = kMaxNumPhotos) {
        log("Requesting data from photos...", withFlag: "!")
        FBRequestConnection.startWithGraphPath("me/photos?limit=\(maxNumPhotos)&\(kPhotosGraphPathFields)",
            completionHandler: { (connection, result, error) -> Void in
                if error == nil {
                    let oldEdgeCount = self.edgeCount
                    let oldEdgeWeight = self.totalEdgeWeight
                    let oldVertexCount = self.names.count
                    var previousPhotoGroup:[UInt64:String] = [UInt64:String]()
                    let allPhotos:AnyObject! = result["data"]!
                    for i:Int in 0..<allPhotos.count {
                        var photoGroup:[UInt64:String] = [UInt64:String]()
                        let photoData:AnyObject! = allPhotos[i]!
                        let (authorId:UInt64, authorName:String) = idAndNameFromObject(photoData["from"]!!)
                        // Build a dictionary of all the people in this photo.
                        photoGroup[authorId] = authorName
                        let photoTags:AnyObject? = photoData["tags"]
                        if photoTags == nil {
                            continue
                        }
                        let photoTagsData:AnyObject! = photoTags!["data"]!
                        for j:Int in 0..<photoTagsData.count {
                            let photoTag:AnyObject! = photoTagsData[j]
                            let (taggedId:UInt64, taggedName:String) = idAndNameFromObject(photoTag)
                            if taggedId != 0 {
                                photoGroup[taggedId] = taggedName
                            }
                        }
                        if photoGroup.count <= 1 || photoGroup.count > kMaxPhotoGroupSize {
                            continue
                        }
                        let dissimilarity:Float = 1.0 - self.similarityOfGroups(photoGroup, second: previousPhotoGroup)
                        let pairwiseWeight:Float = dissimilarity * kMaxPairwisePhotoScore / Float(photoGroup.count - 1)
                        if pairwiseWeight >= kMinPhotoPairwiseWeight {
                            for (node:UInt64, name:String) in photoGroup {
                                self.updateNodeWithId(node, andName: name, andUpdateGender: false)
                            }
                            // Create a fully connected clique using the tagged users.
                            for src:UInt64 in photoGroup.keys {
                                for dst:UInt64 in photoGroup.keys {
                                    if src < dst {
                                        self.connectNode(src, toNode: dst, withWeight: pairwiseWeight)
                                    }
                                }
                            }
                        }
                        previousPhotoGroup = photoGroup
                    }
                    self.pruneGraphByMinWeightThreshold()
                    log("Received \(allPhotos.count) photos (+\(self.names.count - oldVertexCount) nodes, +\(self.edgeCount - oldEdgeCount) edges, +\(self.totalEdgeWeight - oldEdgeWeight) weight).", withIndent:1, withNewline:true)
                    SocialGraphController.sharedInstance.flushGraphToCoreData()
                    SocialGraphController.sharedInstance.didLoadVoteHistoryOrInitializeGraph()
                } else {
                    log("Photos request failed with error \"\(error!.description)\"", withIndent: 1, withFlag: "-", withNewline: true)
                }
        } as FBRequestHandler)
    }

    /**
     * Takes all names that appear as values in self.names and extracts first names. Then
     * adds each first name to self.genders, if it is not already present. New first names
     * are initially mapped to Gender.Undetermined.
     */
    private func updateFirstNames() {
        for (id:UInt64, fullName:String) in self.names {
            let firstName:String = fullName.substringToIndex(fullName.rangeOfString(" ")!.startIndex)
            if self.genders[firstName] == nil {
                self.genders[firstName] = Gender.Undetermined
            }
        }
    }

    /**
     * Makes a request to Parse for the graph rooted at the user given by id. If the graph
     * data exists, updates the graph using the new graph data, introducing new nodes and
     * edges and incrementing existing ones.
     */
    private func fetchAndUpdateGraphDataForFriends(inout idList:[UInt64], numFriendsQueried:Int = 0) {
        let id:UInt64 = popNextHighestConnectedFriend(&idList)
        if numFriendsQueried > kMaxGraphDataQueries || id == 0 {
            log("Done. No more friends to query.", withIndent: 1)
            let timeString:String = String(format: "%.3f", currentTimeInSeconds() - SocialGraphController.sharedInstance.graphInitializeBeginTime)
            log("Time since startup: \(timeString) sec", withIndent: 2, withNewline: true)
            updateGenders()
            updateMedianEdgeWeight()
            log("Graph construction finished! Showing statistics...", withIndent: 1)
            log("Vertex count: \(names.count)", withIndent: 2)
            log("Edge count: \(edgeCount)", withIndent: 2)
            log("Total weight: \(totalEdgeWeight)", withIndent: 2)
            log("Weight baseline: \(baselineEdgeWeight())", withIndent: 2)
            return
        }
        log("Pulling the social graph of root id \(id)...", withFlag: "!")
        var query:PFQuery = PFQuery(className: "GraphData")
        query.whereKey("rootId", equalTo: encodeBase64(id))
        query.findObjectsInBackgroundWithBlock({
            (objects:[AnyObject]!, error:NSError?) -> Void in
            if error != nil || objects.count < 1 {
                log("User \(id)'s graph was not found. Moving on...", withFlag: "?", withIndent: 1)
                self.fetchAndUpdateGraphDataForFriends(&idList, numFriendsQueried: numFriendsQueried)
                return
            }
            let graphData:AnyObject! = objects[0]
            let newNamesObject:AnyObject! = graphData["names"]
            var newNames:[UInt64:String] = [UInt64:String]()
            for nodeAsObject:AnyObject in newNamesObject.allKeys {
                let node:UInt64 = uint64FromAnyObject(nodeAsObject, base64: true)
                newNames[node] = newNamesObject[nodeAsObject.description] as? String
            }
            let newEdges:AnyObject! = graphData["edges"]
            // Parse incoming graph's edges into a dictionary for fast lookup.
            var newEdgeMap:[UInt64:[UInt64:Float]] = [UInt64:[UInt64:Float]]()
            for index in 0..<newEdges.count {
                let edge:AnyObject! = newEdges[index]!
                let src:UInt64 = uint64FromAnyObject(edge[0], base64: true)
                let dst:UInt64 = uint64FromAnyObject(edge[1], base64: true)
                let weight:Float = floatFromAnyObject(edge[2])
                if newEdgeMap[src] == nil {
                    newEdgeMap[src] = [UInt64:Float]()
                }
                if newEdgeMap[dst] == nil {
                    newEdgeMap[dst] = [UInt64:Float]()
                }
                newEdgeMap[src]![dst] = weight
                newEdgeMap[dst]![src] = weight
            }
            var newNodeList:[UInt64] = [UInt64]()
            // Use new edges to determine whether each new node should be added to the graph.
            for (node:UInt64, name:String) in newNames {
                if self.names[node] != nil {
                    continue
                }
                // Check whether the node has enough neighbors in the current social network.
                let neighbors:[UInt64:Float] = newEdgeMap[node]!
                var mutualFriendCount:Int = 0
                for (neighbor:UInt64, weight:Float) in neighbors {
                    if self.names[neighbor] != nil {
                        mutualFriendCount++
                    }
                }
                if mutualFriendCount >= kMutualFriendsThreshold {
                    newNodeList.append(node)
                }
            }
            // Update the graph to contain all the new nodes.
            for newNode:UInt64 in newNodeList {
                self.updateNodeWithId(newNode, andName: newNames[newNode]!)
            }
            // Add all new edges that connect two members of the original graph.
            var edgeUpdateCount:Int = 0
            for (node:UInt64, neighbors:[UInt64:Float]) in newEdgeMap {
                for (neighbor:UInt64, weight:Float) in neighbors {
                    if node < neighbor && self.names[node] != nil && self.names[neighbor] != nil {
                        self.connectNode(node, toNode: neighbor, withWeight: weight)
                        edgeUpdateCount++
                    }
                }
            }
            log("Finished updating graph for root id \(id).", withIndent: 1)
            log("\(newNodeList.count) nodes added; \(edgeUpdateCount) edges updated.", withIndent: 1, withNewline: true)
            self.fetchAndUpdateGraphDataForFriends(&idList, numFriendsQueried: numFriendsQueried + 1)
        })
    }

    /**
     * Helper method that updates this graph given data for one Facebook
     * status.
     */
    private func updateGraphUsingStatus(status:AnyObject!) -> Void {
        var allComments:AnyObject? = status["comments"]
        var previousCommentAuthorId:UInt64 = root;
        if allComments != nil {
            let commentData:AnyObject! = allComments!["data"]!
            for index in 0..<commentData.count {
                let comment:AnyObject! = commentData[index]!
                // Add scores for the author of the comment.
                let from:AnyObject! = comment["from"]!
                let fromId:UInt64 = uint64FromAnyObject(from["id"]!)
                let fromNameObject:AnyObject! = from["name"]!
                updateNodeWithId(fromId, andName: fromNameObject.description!)
                connectNode(root, toNode: fromId, withWeight: kCommentRootScore)
                connectNode(previousCommentAuthorId, toNode: fromId, withWeight: kCommentPrevScore)
                previousCommentAuthorId = fromId
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
                    updateNodeWithId(commentLikeId, andName: commentLikeName)
                    connectNode(commentLikeId, toNode: fromId, withWeight: kCommentLikeScore)
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
                updateNodeWithId(fromId, andName: fromNameObject.description!)
                connectNode(root, toNode: fromId, withWeight: kLikeRootScore)
            }
        }
    }

    /**
     * Computes how "similar" two groups of users are. Returns a
     * float between 0 and 1, inclusive.
     */
    private func similarityOfGroups(first:[UInt64:String], second:[UInt64:String], andIgnoreRoot:Bool = true) -> Float {
        var similarityCount:Float = 0
        var totalCount:Float = 0
        for node:UInt64 in first.keys {
            if andIgnoreRoot && node == root {
                continue
            }
            if second[node] != nil {
                similarityCount++
            }
            totalCount++
        }
        for node:UInt64 in second.keys {
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
     * Compute and store the median edge weight.
     * TODO Maybe automatically update the median edge weight on the
     * fly whenever a new edge is added or an edge is removed?
     */
    private func updateMedianEdgeWeight() {
        var allEdges:[Float] = [Float]()
        for (node:UInt64, neighbors:[UInt64:Float]) in edges {
            for (neighbor:UInt64, weight:Float) in neighbors {
                if node < neighbor {
                    allEdges.append(weight)
                }
            }
        }
        medianEdgeWeight = median(allEdges)
    }

    // MARK: - User action handlers

    /**
     * Notifies the social graph that the user voted on a new match.
     */
    public func userDidMatch(firstId:UInt64, toSecondId:UInt64) {
        walkWeightMultipliers[firstId] = walkWeightBonusForNode(firstId) + kWalkWeightUserMatchBoost
        walkWeightMultipliers[toSecondId] = walkWeightBonusForNode(toSecondId) + kWalkWeightUserMatchBoost
    }

    // MARK: - Parse export functions and subroutines

    /**
     * Asynchronously upload a subset of the graph to the Parse database. Only
     * include edges GREATER THAN a given threshold. By default, kMinExportEdgeWeight
     * is chosen to remove all links that may have occured due to error.
     */
    public func exportGraphToParse(minWeight:Float = kMinExportEdgeWeight, andLoadFriendGraphs:Bool = true) {
        var query:PFQuery = PFQuery(className:"GraphData")
        query.whereKey("rootId", equalTo: encodeBase64(root))
        log("Searching for objectId of \(root)'s graph data...", withFlag: "!")
        query.findObjectsInBackgroundWithBlock({
            (objects:[AnyObject]!, error:NSError?) -> Void in
            var graphData:PFObject = PFObject(className: "GraphData")
            if objects.count > 0 {
                graphData.objectId = objects[0].objectId
                log("Found objectId: \(graphData.objectId)", withIndent: 1, withNewline: true)
            } else {
                log("No existing objectId found.", withIndent: 1, withFlag: "?", withNewline: true)
            }
            graphData["rootId"] = encodeBase64(self.root)
            var edgeArray:[[NSString]] = [[NSString]]()
            var nameDictionary:[NSString:NSString] = [NSString:NSString]()
            for (node:UInt64, neighbors:[UInt64:Float]) in self.edges {
                for (neighbor:UInt64, var weight:Float) in neighbors {
                    if node == self.root || neighbor == self.root {
                        weight *= kScaleFactorForExportingRootEdges
                    }
                    if node < neighbor && weight > minWeight {
                        let weightAsTruncatedString:String = String(format: "%.2f", weight)
                        let base64Node:String = encodeBase64(node)
                        let base64Neighbor:String = encodeBase64(neighbor)
                        edgeArray.append([base64Node, base64Neighbor, weightAsTruncatedString])
                        if nameDictionary[base64Node] == nil {
                            nameDictionary[base64Node] = self.names[node]
                        }
                        if nameDictionary[base64Neighbor] == nil {
                            nameDictionary[base64Neighbor] = self.names[neighbor]
                        }
                    }
                }
            }
            graphData["names"] = nameDictionary
            graphData["edges"] = edgeArray
            log("Saving graph with \(nameDictionary.count) nodes, \(edgeArray.count) edges.", withFlag: "!")
            graphData.saveInBackgroundWithBlock({
                (succeeded:Bool, error:NSError?) -> Void in
                if succeeded && error == nil {
                    log("Successfully saved graph to Parse.", withIndent: 1, withNewline: true)
                    if andLoadFriendGraphs {
                        self.updateGraphDataFromFriends()
                    }
                } else {
                    if error == nil {
                        log("Failed to save graph to Parse.", withIndent: 1, withFlag: "-", withNewline: true)
                    } else {
                        log("Error \"\(error!.description)\" occurred while saving to Parse.", withIndent: 1, withFlag: "-", withNewline: true)
                    }
                }
            })
        })
    }

    /**
     * Given a list of friends, pops off the next highest connected friend and
     * returns the friend's id.
     */
    private func popNextHighestConnectedFriend(inout friendList:[UInt64]) -> UInt64 {
        if friendList.count == 0 {
            return 0
        }
        var maxFriendWeight:Float = -Float.infinity
        var nextFriend:UInt64 = 0
        var maxFriendIndex:Int = 0
        for index:Int in 0..<friendList.count {
            let friend:UInt64 = friendList[index]
            var friendWeight:Float;
            if self.names[friend] == nil {
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

    // MARK: - Random walk functions and subroutines

    /**
     * Samples some number of users by performing a weighted random walk on the
     * graph starting at the root user.
     */
    public func updateRandomSample(size:Int = kRandomSampleCount) {
        currentSample.removeAll(keepCapacity: true)
        var sample:NSMutableSet = NSMutableSet()
        var nextStep:UInt64 = root
        while sample.count < size {
            nextStep = takeRandomStepFrom(nextStep, withNodesTraversed: sample)
            if nextStep == 0 {
                nextStep = sampleRandomNode(sample)
            }
            sample.addObject(nextStep.description)
        }
        for idAsObject:AnyObject in sample {
            let id:UInt64 = uint64FromAnyObject(idAsObject)
            currentSample.append(id)
        }
        if kShowRandomWalkDebugOutput {
            println("    Done. Final random walk result...")
            for idAsObject:AnyObject in sample {
                let id:UInt64 = uint64FromAnyObject(idAsObject)
                println("        \(names[id]!) (\(id))")
            }
            println()
        }
        updateWalkWeightMultipliersAfterRandomSample()
    }

    /**
     * Given a current node and a list of nodes previously traversed, randomly jumps
     * to a new neighboring node that does not already appear in the list of previous
     * nodes and is not the root. If there is no such node, returns 0.
     */
    private func takeRandomStepFrom(node:UInt64, withNodesTraversed:NSMutableSet) -> UInt64 {
        var possibleNextNodes:[(UInt64, Float)] = [(UInt64, Float)]()
        var originalNormalizedWeights:[Float] = [Float]() // Debugging purposes.
        let currentGender:Gender = node == root ? Gender.Undetermined : genderFromID(node)
        var sameGenderScoreSum:Float = 0
        var differentGenderScoreSum:Float = 0
        let meanNonRootWeight:Float = baselineEdgeWeight()
        // Compute sampling weights prior to gender renormalization.
        for (neighbor:UInt64, weight:Float) in self.edges[node]! {
            if neighbor == root || withNodesTraversed.containsObject(neighbor.description) {
                continue
            }
            let neighborScore:Float = sampleWeightForScore(weight - meanNonRootWeight)
            possibleNextNodes.append((neighbor, neighborScore))
            originalNormalizedWeights.append(weight - meanNonRootWeight)
            let gender:Gender = genderFromID(neighbor)
            if currentGender == Gender.Undetermined || gender == Gender.Undetermined {
                continue
            } else if gender == currentGender {
                sameGenderScoreSum += neighborScore
            } else {
                differentGenderScoreSum += neighborScore
            }
        }
        if currentGender != Gender.Undetermined {
            // Apply gender renormalization.
            let newSameGenderScoreSum:Float = (sameGenderScoreSum + differentGenderScoreSum) / Float(1 + kGenderBiasRatio)
            let newDifferentGenderScoreSum:Float = kGenderBiasRatio * newSameGenderScoreSum
            for index in 0..<possibleNextNodes.count {
                let (neighbor:UInt64, weight:Float) = possibleNextNodes[index]
                let gender:Gender = genderFromID(neighbor)
                if gender != Gender.Undetermined {
                    if gender == currentGender {
                        possibleNextNodes[index].1 *= newSameGenderScoreSum / sameGenderScoreSum
                    } else {
                        possibleNextNodes[index].1 *= newDifferentGenderScoreSum / differentGenderScoreSum
                    }
                }
            }
        }
        // Apply random walk multipliers.
        for index in 0..<possibleNextNodes.count {
            let (neighbor:UInt64, weight:Float) = possibleNextNodes[index]
            possibleNextNodes[index].1 *= 1.0 + walkWeightBonusForNode(neighbor)
        }
        if kShowRandomWalkDebugOutput {
            if withNodesTraversed.count == 0 {
                println("[!] Beginning random walk...")
            }
            print("    [\(withNodesTraversed.count + 1)] Now at \(names[node]!) (\(genderFromID(node).toString()))\n")
            if possibleNextNodes.count == 0 {
                println("        No unvisited neighbors to step to!")
            } else {
                var total:Float = 0
                for (id:UInt64, weight:Float) in possibleNextNodes {
                    total += weight
                }
                for index:Int in 0..<possibleNextNodes.count {
                    let (neighbor:UInt64, weight:Float) = possibleNextNodes[index]
                    let percentage:Double = Double(100.0 * (weight/total))
                    var percentageAsString:String
                    if percentage < 10.0 {
                        percentageAsString = String(format: "%.3f", percentage)
                    } else if percentage < 100.0 {
                        percentageAsString = String(format: "%.2f", percentage)
                    } else {
                        percentageAsString = String(format: "%.1f", percentage)
                    }
                    let multiplierAsString = String(format: "%.2f", walkWeightBonusForNode(neighbor))
                    let weightAsString:String = String(format: "%.2f", originalNormalizedWeights[index])
                    var nameAsPaddedString:String = names[neighbor]!
                    if nameAsPaddedString.utf16Count < 30 {
                        for index in nameAsPaddedString.utf16Count..<30 {
                            nameAsPaddedString += " "
                        }
                    }
                    print("        ")
                    print("\(percentageAsString)% \(nameAsPaddedString)  ")
                    if multiplierAsString[multiplierAsString.startIndex] == "-" {
                        print("\(multiplierAsString)  ")
                    } else {
                        print(" \(multiplierAsString)  ")
                    }
                    if weightAsString[weightAsString.startIndex] == "-" {
                        println("\(weightAsString)")
                    } else {
                        println(" \(weightAsString)")
                    }
                }
            }
        }
        return weightedRandomSample(possibleNextNodes)
    }

    /**
     * Computes the walk weight multiplier for a node. By default, this is 1 (no change).
     */
    private func walkWeightBonusForNode(id:UInt64) -> Float {
        if walkWeightMultipliers[id] == nil {
            return 0
        }
        return walkWeightMultipliers[id]!
    }

    /**
     * Update walk weight multipliers. This means decaying all existing multipliers and
     * applying a penalty to all nodes chosen in the current random sample.
     */
    private func updateWalkWeightMultipliersAfterRandomSample() {
        for (node:UInt64, multiplier:Float) in walkWeightMultipliers {
            walkWeightMultipliers[node] = kWalkWeightDecayRate * multiplier
        }
        for node:UInt64 in currentSample {
            let newWeight:Float = walkWeightBonusForNode(node) - kWalkWeightPenalty
            if newWeight <= -1.0 {
                walkWeightMultipliers[node] = -0.9
            } else {
                walkWeightMultipliers[node] = newWeight
            }
        }
        // Clean the walk weight multipliers dictionary.
        var nodesToRemove:[UInt64] = []
        for (node:UInt64, multiplier:Float) in walkWeightMultipliers {
            if abs(multiplier) < 0.1 {
                nodesToRemove.append(node)
            }
        }
        for node:UInt64 in nodesToRemove {
            walkWeightMultipliers[node] = nil
        }
    }

    /**
     * Computes the sampling weight of an edge using a sigmoid function with range
     * between 0 and withLimit.
     */
    private func sampleWeightForScore(score:Float, withLimit:Float = kSamplingWeightLimit) -> Float {
        return withLimit / (1.0 + pow(kSigmoidExponentialBase, -score))
    }

    /**
     * Randomly samples a node in the graph.
     * TODO Add gendered bias.
     */
    private func sampleRandomNode(withNodesTraversed:NSMutableSet, andIgnoreRoot:Bool = true) -> UInt64 {
        var possibleNextNodes:[UInt64] = [UInt64]()
        for (neighbor:UInt64, temp:String) in self.names {
            if withNodesTraversed.containsObject(neighbor.description) || (andIgnoreRoot && neighbor == root) {
                continue
            }
            possibleNextNodes.append(neighbor)
        }
        return possibleNextNodes[randomInt(possibleNextNodes.count)]
    }

    /**
     * Computes the baseline average weight for the nodes. This
     * is the mean weight of edges, not including those connecting
     * root nodes.
     */
    private func baselineEdgeWeight() -> Float {
        if medianEdgeWeight != nil {
            return medianEdgeWeight!
        }
        return (totalEdgeWeight - totalEdgeWeightFromRoot) / Float(edgeCount - edges[root]!.count)
    }

    /**
     * Shortcut for finding the gender given user ID. Uses the graph's data structures
     * to map ID -> name -> first name -> gender. Returns Gender.Undetermined if ID
     * lookup failed.
     */
    private func genderFromID(id:UInt64) -> Gender {
        if let name:String = names[id] {
            let firstName:String = firstNameFromFullName(name)
            return genders[firstName] == nil ? Gender.Undetermined : genders[firstName]!
        }
        return Gender.Undetermined
    }

    /**
     * Counts the overall gender of people in the social network, not
     * counting the root user. Returns a tuple of the form (# male, #
     * female, # undetermined).
     */
    private func overallGenderCount() -> (Int, Int, Int) {
        var mcount:Int = 0
        var fcount:Int = 0
        var ucount:Int = 0
        for (id:UInt64, name:String) in names {
            if id == root {
                continue
            }
            let gender:Gender = genderFromID(id)
            switch gender {
            case .Undetermined:
                ucount++
                break
            case .Male:
                mcount++
                break
            case .Female:
                fcount++
                break
            }
        }
        return (mcount, fcount, ucount)
    }
    
    // MARK: - Instance variables

    // Core app-related data.
    var root:UInt64
    var edges:[UInt64:[UInt64:Float]]
    var names:[UInt64:String]
    var genders:[String:Gender]
    var currentSample:[UInt64]

    // Edge-based metadata for computing heuristics.
    var totalEdgeWeight:Float
    var edgeCount:Int
    var totalEdgeWeightFromRoot:Float

    // Match graph used to improve heuristics.
    var matches:MatchGraph?
    var walkWeightMultipliers:[UInt64:Float]

    // Miscellaneous state variables.
    var isCurrentlyUpdatingGender:Bool
    var shouldReupdateGender:Bool
    var didLoadGendersFromCache:Bool
    var medianEdgeWeight:Float? = nil

    // For thread safety.
    var genderUpdateSemaphore = dispatch_semaphore_create(1)
}
