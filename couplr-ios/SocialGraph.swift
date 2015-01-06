//
//  SocialGraph.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 12/26/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import Parse

/**
 * It's not quite politically correct, but it's a start.
 * TODO Better support for non-heteronormativity.
 */
public enum Gender {
    case Male, Female, Undetermined
    public func description() -> String {
        switch self {
        case .Male:
            return "male"
        case .Female:
            return "female"
        case .Undetermined:
            return "undetermined"
        }
    }
}

/**
 * Maps "male" to Gender.Male, "female" to Gender.Female, and anything
 * else to Undetermined.
 */
func genderFromString(gender:String) -> Gender {
    let lowercaseGender:String = gender.lowercaseString
    if lowercaseGender == "female" {
        return Gender.Female
    } else if lowercaseGender == "male" {
        return Gender.Male
    }
    return Gender.Undetermined
}

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
        self.genders = [String:Gender]()
        self.isCurrentlyUpdatingGender = false
        self.shouldReupdateGender = false
        updateFirstNames()
    }
    
    public var description:String {
        return toString()
    }

    /**
     * Returns the connection weight between two given nodes.
     */
    public subscript(node:UInt64, toNode:UInt64) -> Float {
        return weightFrom(node, toNode:toNode)
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
    
    /**
     * Update the graph with a new node and name. Adds the new node to the name
     * mapping if it does not already appear. Also adds the first name to the
     * gender mapping if the first name does not already appear, with an initial
     * value of Gender.Undetermined.
     */
    public func updateNodeWithID(id:UInt64, andName:String) {
        if names[id] == nil {
            names[id] = andName
            let firstName:String = firstNameFromFullName(andName)
            if genders[firstName] == nil {
                genders[firstName] = Gender.Undetermined
            }
        }
    }

    /**
     * Load a map from first name to gender using the first names encountered
     * in the graph. Sends a request for each first name for which gender is
     * currently unknown. Initially, the gender dictionary maps all first names
     * to Gender.Undetermined.
     *
     * If another gender update is currently taking place when this function is
     * invoked, it will wait until the first response is received before executing.
     */
    public func updateGenders() {
        if isCurrentlyUpdatingGender {
            shouldReupdateGender = true
        }
        log("Requesting gender update...", withFlag:"!")
        isCurrentlyUpdatingGender = true
        updateFirstNames()
        let addGenders:(NSData?, NSURLResponse?, NSError?) -> Void = {
            (data:NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil {
                let jsonData:Array<NSDictionary> = parseArrayFromJSONData(data!)
                for index in 0..<jsonData.count {
                    let genderResponseObject:AnyObject! = jsonData[index]
                    let nameObject:AnyObject! = genderResponseObject["name"]!
                    let genderObject:AnyObject! = genderResponseObject["gender"]!
                    let (firstName:String, gender:String) = (nameObject.description, genderObject.description)
                    self.genders[firstName] = genderFromString(gender)
                }
                let (males:Int, females:Int, undetermined:Int) = self.overallGenderCount()
                log("Gender response received (\(jsonData.count) predictions).", withIndent:1)
                log("Current breakdown: \(males) males, \(females) females, \(undetermined) undetermined.", withIndent:1)
            }
            self.isCurrentlyUpdatingGender = false
            if self.shouldReupdateGender {
                self.shouldReupdateGender = false
                self.updateGenders()
            }
        }
        var requestURL:String = kGenderizeURLPrefix
        var counter:Int = 0
        for (firstName:String, gender:Gender) in genders {
            if gender == Gender.Undetermined {
                requestURL += "name[\(counter)]=\(firstName)&"
                counter++
            }
        }
        if genders.count > 0 {
            requestURL = requestURL.substringToIndex(requestURL.endIndex.predecessor())
            getRequestToURL(requestURL, addGenders)
        }
    }

    /**
     * Given a set of IDs indicating comments with likes, queries the Facebook
     * API for the list of friends who liked the comments and updates the graph
     * data with the corresponding information.
     */
    public func updateCommentLikes(commentsWithLikes:[String:UInt64], andSaveGraphData:Bool) {
        log("Requesting \(commentsWithLikes.count) liked comments...", withFlag:"!")
        var remainingCommentsWithLikes:[String:UInt64] = [String:UInt64]()
        let handler:(AnyObject?, AnyObject?, AnyObject?)->() = { (connection, result, error) -> Void in
            if error == nil {
                let responseCount:Int = result!.count
                var totalLikeCount:Int = 0;
                for index in 0..<responseCount {
                    let responseBody:String! = result![index]!["body"]! as? String!
                    let responseJSON:JSON! = JSON.parse(responseBody)
                    let commentID:String = responseJSON["id"].description
                    var commentAuthor:UInt64? = commentsWithLikes[commentID]
                    if commentAuthor == nil {
                        continue
                    }
                    let likesArray:JSON = responseJSON["likes"]["data"]
                    for index in 0..<likesArray.length {
                        let likeJSON:JSON = likesArray[index]
                        let id:UInt64 = uint64FromAnyObject(likeJSON["id"].asString!)
                        let name:String = likeJSON["name"].asString!
                        if commentAuthor == id {
                            continue
                        }
                        if self.names[id] == nil {
                            // Introduce a new node to the graph.
                            self.updateNodeWithID(id, andName: name)
                        }
                        totalLikeCount++
                        self.connectNode(commentAuthor!, toNode:id, withWeight:kCommentLikeScore)
                    }
                }
                log("Loaded \(totalLikeCount) comment likes.", withIndent:1)
                if remainingCommentsWithLikes.count > 0 {
                    log("\(remainingCommentsWithLikes.count) remaining comments. Continuing query...", withIndent:1)
                    self.updateCommentLikes(remainingCommentsWithLikes, andSaveGraphData:andSaveGraphData)
                } else if andSaveGraphData {
                    self.saveGraphData()
                }
            }
        }
        var requests:[[String:String]] = []
        for (id:String, author:UInt64) in commentsWithLikes {
            if requests.count >= kMaxAllowedBatchRequestSize {
                remainingCommentsWithLikes[id] = author
            } else {
                let graphPath:String = "\(id)?fields=likes"
                let dictionary:NSDictionary = NSDictionary()
                requests.append(["method":"GET", "relative_url":graphPath])
            }
        }
        var encodingError:NSError? = nil
        let jsonData:NSData? = NSJSONSerialization.dataWithJSONObject(requests, options: nil, error: &encodingError)
        var jsonString:NSString = NSString(data:jsonData!, encoding:NSUTF8StringEncoding)!
        let params:NSDictionary = NSDictionary(dictionary: ["batch": jsonString])
        FBRequestConnection.startWithGraphPath("", parameters: params, HTTPMethod:"POST", completionHandler:handler)
    }
    
    /**
     * Asynchronously upload a subset of the graph to the Parse database. Only
     * include edges GREATER THAN a given threshold. By default, kCommentPrevScore
     * is chosen to remove all links that may have occured due to error.
     */
    public func saveGraphData(minWeight:Float = kCommentPrevScore) {
        var query:PFQuery = PFQuery(className:"GraphData")
        query.whereKey("rootId", equalTo:NSNumber(unsignedLongLong:root))
        log("Searching for objectId of \(root)'s graph data...", withFlag:"!")
        query.findObjectsInBackgroundWithBlock({
            (objects:[AnyObject]!, error:NSError?) -> Void in
            var graphData:PFObject = PFObject(className:"GraphData")
            if objects.count > 0 {
                graphData.objectId = objects[0].objectId
                log("Found objectId: \(graphData.objectId)", withIndent:1)
            } else {
                log("No existing objectId found.", withIndent:1, withFlag:"?")
            }
            graphData["rootId"] = NSNumber(unsignedLongLong:self.root)
            var edgeArray:[[NSNumber]] = [[NSNumber]]()
            var nameDictionary:[NSString:NSString] = [NSString:NSString]()
            for (node:UInt64, neighbors:[UInt64:Float]) in self.edges {
                let nodeNum:NSNumber = NSNumber(unsignedLongLong:node)
                let nodeAsString:NSString = nodeNum.stringValue
                for (neighbor:UInt64, var weight:Float) in neighbors {
                    if node == self.root || neighbor == self.root {
                        weight /= 5 // TODO Normalize this to number of comments or something?
                    }
                    if node < neighbor && weight > minWeight {
                        let neighborNum:NSNumber = NSNumber(unsignedLongLong:neighbor)
                        let neighborAsString:NSString = neighborNum.stringValue
                        edgeArray.append([nodeNum, neighborNum, weight])
                        if nameDictionary[nodeAsString] == nil {
                            nameDictionary[nodeAsString] = self.names[node]
                        }
                        if nameDictionary[neighborAsString] == nil {
                            nameDictionary[neighborAsString] = self.names[neighbor]
                        }
                    }
                }
            }
            graphData["names"] = nameDictionary
            graphData["edges"] = edgeArray
            log("Saving graph with \(nameDictionary.count) nodes, \(edgeArray.count) edges.", withFlag:"!", withIndent:1)
            graphData.saveInBackgroundWithBlock({
                (succeeded:Bool, error:NSError?) -> Void in
                if succeeded && error == nil {
                    log("Successfully saved graph to Parse.", withIndent:1, withFlag:"+")
                    self.updateGraphData()
                } else if error != nil {
                    log("An error occured while saving to Parse.", withIndent:1, withFlag:"-")
                } else {
                    log("Unknown error occurred while saving to Parse.", withIndent:1, withFlag:"?")
                }
            })
        })
    }

    /**
     * Adds an undirected edge between two users, implemented as two directed
     * edges in reverse directions. Using connectNode to modify the graph will
     * enforce symmetry.
     */
    public func connectNode(node:UInt64, toNode:UInt64, withWeight:Float = 1) {
        if !hasEdgeFromNode(node, to:toNode) {
            edgeCount++
        }
        totalEdgeWeight += withWeight
        addEdgeFrom(node, toNode:toNode, withWeight:withWeight)
        addEdgeFrom(toNode, toNode:node, withWeight:withWeight)
    }

    /**
     * Removes all edges between two users. Using disconnectNode to modify the
     * graph will enforce symmetry.
     */
    public func disconnectNode(node:UInt64, fromNode:UInt64) {
        let currentEdgeWeight:Float = self[node, fromNode]
        if currentEdgeWeight > kUnconnectedEdgeWeight {
            edgeCount--
            totalEdgeWeight -= currentEdgeWeight
            removeEdgeFrom(node, toNode:fromNode)
            removeEdgeFrom(fromNode, toNode:node)
        }
    }

    /**
     * Samples some number of users by performing a weighted random walk on the
     * graph starting at the root user.
     */
    public func randomSample(size:Int = kRandomSampleCount) -> [UInt64:String] {
        var sample:[UInt64:String] = [root:names[root]!]
        var nextStep:UInt64 = takeRandomStepFrom(root, withNodesTraversed:sample)
        while sample.count <= size {
            if nextStep == 0 {
                nextStep = sampleRandomNode(sample)
            }
            sample[nextStep] = names[nextStep]!
            if sample.count <= size {
                nextStep = takeRandomStepFrom(nextStep, withNodesTraversed:sample)
            }
        }
        sample[root] = nil
        if kShowRandomWalkDebugOutput {
            println("    Done. Final random walk result...")
            for (id:UInt64, name:String) in sample {
                println("        \(name) (\(id))")
            }
            println()
        }
        return sample
    }
    
    /**
     * Returns whether or not two nodes are connected. Assumes that all edges are undirected.
     */
    public func hasEdgeFromNode(node:UInt64, to:UInt64) -> Bool {
        return self[node, to] > kUnconnectedEdgeWeight
    }
    
    /**
     * Queries the Facebook API for the user's friends, and uses the information to fetch
     * graph data from Parse. Only keeps one active request at a time, and makes a maximum
     * of maxNumFriends requests before stopping.
     */
    public func updateGraphData(maxNumFriends:Int = kMaxGraphDataQueries) {
        log("Fetching friends list...", withFlag:"!")
        let request:FBRequest = FBRequest.requestForMyFriends()
        request.startWithCompletionHandler{(connection:FBRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
            if error == nil {
                var couplrFriends:[UInt64] = [UInt64]()
                let friendsData:AnyObject! = result["data"]!
                for index in 0..<friendsData.count {
                    let friendObject:AnyObject! = friendsData[index]!
                    couplrFriends.append(uint64FromAnyObject(friendObject["id"]))
                }
                log("Found \(couplrFriends.count) friend(s).", withIndent:1)
                self.fetchAndUpdateGraphDataForFriends(&couplrFriends)
            }
        }
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
    
    /**
     * Makes a request to Parse for the graph rooted at the user given by id. If the graph
     * data exists, updates the graph using the new graph data, introducing new nodes and
     * edges and incrementing existing ones.
     */
    private func fetchAndUpdateGraphDataForFriends(inout idList:[UInt64], numFriendsQueried:Int = 0) {
        let id:UInt64 = popNextHighestConnectedFriend(&idList)
        if numFriendsQueried > kMaxGraphDataQueries || id == 0 {
            log("Done. No more friends to query.")
            updateGenders()
            return
        }
        log("Pulling the social graph of root id \(id)...", withFlag:"!")
        var query:PFQuery = PFQuery(className:"GraphData")
        query.whereKey("rootId", equalTo: NSNumber(unsignedLongLong:id))
        query.findObjectsInBackgroundWithBlock({
            (objects:[AnyObject]!, error:NSError?) -> Void in
            if error != nil || objects.count < 1 {
                log("User \(id)'s graph was not found. Moving on...", withFlag:"?", withIndent:1)
                self.fetchAndUpdateGraphDataForFriends(&idList, numFriendsQueried: numFriendsQueried)
                return
            }
            let graphData:AnyObject! = objects[0]
            let newNamesObject:AnyObject! = graphData["names"]
            var newNames:[UInt64:String] = [UInt64:String]()
            for nodeAsObject:AnyObject in newNamesObject.allKeys {
                let node:UInt64 = uint64FromAnyObject(nodeAsObject)
                newNames[node] = newNamesObject[nodeAsObject.description] as? String
            }
            let newEdges:AnyObject! = graphData["edges"]
            // Parse incoming graph's edges into a dictionary for fast lookup.
            var newEdgeMap:[UInt64:[UInt64:Float]] = [UInt64:[UInt64:Float]]()
            for index in 0..<newEdges.count {
                let edge:AnyObject! = newEdges[index]!
                let src:UInt64 = uint64FromAnyObject(edge[0])
                let dst:UInt64 = uint64FromAnyObject(edge[1])
                let weight:Float = Float(edge[2] as NSNumber)
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
                if mutualFriendCount >= 2 {
                    newNodeList.append(node)
                }
            }
            // Update the graph to contain all the new nodes.
            for newNode:UInt64 in newNodeList {
                self.updateNodeWithID(newNode, andName:newNames[newNode]!)
            }
            // Add all new edges that connect two members of the original graph.
            var edgeUpdateCount:Int = 0
            for (node:UInt64, neighbors:[UInt64:Float]) in newEdgeMap {
                for (neighbor:UInt64, weight:Float) in neighbors {
                    if node < neighbor && self.names[node] != nil && self.names[neighbor] != nil {
                        self.connectNode(node, toNode:neighbor, withWeight:weight)
                        edgeUpdateCount++
                    }
                }
            }
            log("Finished updating graph for root id \(id).", withIndent:1)
            log("\(newNodeList.count) nodes added; \(edgeUpdateCount) edges updated.", withIndent:1)
            self.fetchAndUpdateGraphDataForFriends(&idList, numFriendsQueried: numFriendsQueried + 1)
        })
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
     * Computes the gender bias for the next hop node using the current gender ratio.
     */
    private func genderMultiplierForNextHopNode(nextHop:UInt64, withGenderRatio:(Float, Float)) -> Float {
        let nextHopGender:Gender = genderFromID(nextHop)
        var genderExponent:Float = 0
        switch nextHopGender {
        case .Undetermined:
            genderExponent = 0
        case .Male:
            genderExponent = kGenderMultiplierMaxExponent * (2 * withGenderRatio.1 - 1)
        case .Female:
            genderExponent = kGenderMultiplierMaxExponent * (2 * withGenderRatio.0 - 1)
        }
        return pow(kGenderMultiplierBase, genderExponent)
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

    /**
     * Returns the ratio of known male and females in a set of nodes. Skips over Undetermined
     * genders as well as the root node (i.e. they are simply not counted as male or female).
     * The output will sum to 1. If no known males or females were encountered, the output
     * defaults to (0.5, 0.5)
     */
    private func genderRatioForNodes(nodesTraversed:[UInt64:String]) -> (Float, Float) {
        var mcount:Float = 0
        var fcount:Float = 0
        for (id:UInt64, name:String) in nodesTraversed {
            if id == root {
                continue
            }
            let gender:Gender = genderFromID(id)
            switch gender {
            case .Undetermined:
                break
            case .Male:
                mcount++
                break
            case .Female:
                fcount++
                break
            }
        }
        if mcount == 0 && fcount == 0 {
            return (0.5, 0.5)
        }
        let total:Float = mcount + fcount
        return (mcount/total, fcount/total)
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
    private func sampleRandomNode(withNodesTraversed:[UInt64:String]) -> UInt64 {
        var possibleNextNodes:[UInt64] = [UInt64]()
        for (neighbor:UInt64, temp:String) in self.names {
            if withNodesTraversed[neighbor] != nil {
                continue
            }
            possibleNextNodes.append(neighbor)
        }
        return possibleNextNodes[randomInt(possibleNextNodes.count)]
    }

    /**
     * Given a current node and a list of nodes previously traversed, randomly jumps
     * to a new neighboring node that does not already appear in the list of previous
     * nodes. If there is no such node, returns 0.
     */
    private func takeRandomStepFrom(node:UInt64, withNodesTraversed:[UInt64:String]) -> UInt64 {
        var possibleNextNodes:[(UInt64, Float)] = [(UInt64, Float)]()
        let genderRatio:(Float, Float) = genderRatioForNodes(withNodesTraversed)
        var normalizedWeights:[UInt64:Float] = normalizedEdgeWeightsForNode(node, withNodesTraversed: withNodesTraversed)
        for (neighbor:UInt64, weight:Float) in normalizedWeights {
            let multiplier:Float = genderMultiplierForNextHopNode(neighbor, withGenderRatio: genderRatio)
            let sampleWeight:Float = multiplier * sampleWeightForScore(weight)
            possibleNextNodes.append((neighbor, sampleWeight))
        }
        if kShowRandomWalkDebugOutput {
            if withNodesTraversed.count == 1 {
                println("[!] Beginning random walk...")
            }
            print("    [\(withNodesTraversed.count)] Now at \(names[node]!).")
            let maleRatioRounded:String = String(format: "%.2f", genderRatio.0)
            let femaleRatioRounded:String = String(format: "%.2f", genderRatio.1)
            println(" (m:f = \(maleRatioRounded):\(femaleRatioRounded))")
            if possibleNextNodes.count == 0 {
                println("        No unvisited neighbors to step to!")
            } else {
                var total:Float = 0
                for (id:UInt64, weight:Float) in possibleNextNodes {
                    total += weight
                }
                for (id:UInt64, weight:Float) in possibleNextNodes {
                    let percentageAsString:String = String(format: "%.2f", Double(100.0 * (weight/total)))
                    println("        \(names[id]!): \(percentageAsString)% (w=\(normalizedWeights[id]!))")
                }
            }
        }
        return weightedRandomSample(possibleNextNodes)
    }
    
    /**
     * Computes the normalized weights for a node. Ignores any node that has already
     * been traversed. The resulting edges range between -1 and 1 (the lowest weight
     * maps to -1 and the highest weight to 1, with all other weights linearly scaling
     * on the interval [-1, 1]). If all edges are the same weight, simply maps each
     * edge to 0.
     */
    private func normalizedEdgeWeightsForNode(node:UInt64, withNodesTraversed:[UInt64:String]) -> [UInt64:Float] {
        var normalizedWeights:[UInt64:Float] = [UInt64:Float]()
        var minWeight:Float = Float.infinity
        var maxWeight:Float = -Float.infinity
        for (neighbor:UInt64, weight:Float) in edges[node]! {
            if withNodesTraversed[neighbor] != nil {
                continue
            }
            normalizedWeights[neighbor] = weight
            if weight < minWeight {
                minWeight = weight
            }
            if weight > maxWeight {
                maxWeight = weight
            }
        }
        if normalizedWeights.count == 0 {
            return normalizedWeights
        }
        let normalizedGap:Float = kNormalizedEdgeWeightRange.1 - kNormalizedEdgeWeightRange.0
        let scalar:Float = normalizedGap / (maxWeight - minWeight)
        // TODO Maybe using <> comparison here is safer?
        let allEdgesHaveEqualWeight:Bool = minWeight == maxWeight
        for (neighbor:UInt64, weight:Float) in normalizedWeights {
            if allEdgesHaveEqualWeight {
                normalizedWeights[neighbor] = (normalizedGap / 2) + kNormalizedEdgeWeightRange.0
            } else {
                normalizedWeights[neighbor] = (weight - minWeight) * scalar + kNormalizedEdgeWeightRange.0
            }
        }
        return normalizedWeights
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
        var currentWeight:Float = weightFrom(node, toNode:toNode)
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
        }
    }

    /**
     * Returns the connection weight between two given nodes.
     */
    private func weightFrom(node:UInt64, toNode:UInt64) -> Float {
        return (edges[node] == nil || edges[node]![toNode] == nil) ? kUnconnectedEdgeWeight : edges[node]![toNode]!
    }
    
    // Core app-related data.
    var root:UInt64
    var edges:[UInt64:[UInt64:Float]]
    var names:[UInt64:String]
    var genders:[String:Gender]

    // Edge-based metadata for future heuristics.
    var totalEdgeWeight:Float
    var edgeCount:Int
    
    // Miscellaneous state variables.
    var isCurrentlyUpdatingGender:Bool
    var shouldReupdateGender:Bool
}
