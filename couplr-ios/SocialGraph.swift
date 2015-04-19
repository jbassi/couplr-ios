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
let kMinNumPosts:Int = 100                          // Number of posts to query.
let kMaxNumPhotos:Int = 200                         // Number of photos to query.
let kMaxPhotoGroupSize:Int = 15                     // Max number of people considered in a photo.
let kMinGraphEdgeWeight:Float = 0.25                // The minimum edge weight threshold when cleaning the graph.
let kMatchExistsBetweenUsersWeight:Float = 1        // The connection weight between two users who are matched at least once.
let kUserMatchVoteScore:Float = 1.0                 // Score for the user voting on title for a match.
// Like and comment scores.
let kCommentRootScore:Float = 0.5                   // Score for commenting on the root user's status.
let kCommentPrevScore:Float = 0.1                   // Score for being the next to comment on the root user's status.
let kLikeRootScore:Float = 0.2                      // Score for a like on the root user's status.
let kCommentLikeScore:Float = 0.4                   // Score for a like on someone's comment on the root user's status.
// Constants for scoring photo data.
let kMaxPairwisePhotoScore:Float = 2.0              // A base photo score for a picture containing only 2 people.
let kMinPhotoPairwiseWeight:Float = 0.1             // Only add edges from photo data with at least this weight.

let kSamplingWeightLimit:Float = 10                 // The coefficient for the sigmoid function.
let kSigmoidExponentialBase:Float = 2.0             // The exponential base for the sigmoid function.
let kRandomSampleCount:Int = 9                      // The number of people to randomly sample.
let kExpectedNumRandomHops:Float = 1.0              // The expected number of random hops when performing random walk sampling.

let kMaxGraphDataQueries:Int = 5                    // Max number of friends to query graph data from.
let kMinExportEdgeWeight:Float = 0.75               // Only export edges with more than this weight.
let kScaleFactorForExportingRootEdges:Float = 0.25  // Export root edges scaled by this number.
let kMutualFriendsThreshold:Int = 5                 // This many mutual friends to pull a friend over to the user's graph.
let kUseMedianAsWeightBaseline:Bool = false         // Whether to use median for the baseline (if false, mean is used).

let kGenderBiasRatio:Float = 4.0                    // Make it this much more likely to land on the opposite gender.
let kWalkWeightUserMatchBoost:Float = 1.5           // The walk weight "bonus" for a node when the user selects a match.
let kWalkWeightDecayRate:Float = 0.5                // The decay rate for the walk weight bonus.
let kWalkWeightPenalty:Float = 0.5                  // Constant penalty per step to encourage choosing new nodes.
// Debugging output
let kShowRandomWalkDebugOutput:Bool = false

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
    public init(root:UInt64, nodes:[UInt64:String]) {
        self.root = root
        self.nodes = nodes
        self.names = [UInt64:String]()
        for (id:UInt64,name:String) in nodes {
            self.names[id] = name
        }
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
        var out:String = "{"
        out += "\"node_count\":\(self.nodes.count),"
        out += "\"edge_count\":\(edgeCount),"
        out += "\"total_weight\":\(totalEdgeWeight),"
        out += "\"root\":\"\(root)\","
        out += "\"edges\":{"
        for (outerIndex:Int, (node:UInt64, neighbors)) in enumerate(edges) {
            out += "\"\(String(node))\":{"
            for (innerIndex:Int, (neighbor:UInt64, weight:Float)) in enumerate(neighbors) {
                out += "\"\(neighbor)\":\(weight)"
                if innerIndex != neighbors.count - 1 {
                    out += ","
                }
            }
            out += "}"
            if outerIndex != edges.count - 1 {
                out += ","
            }
        }
        out += "},"
        out += "\"nodes\":{"
        for (index:Int, (node:UInt64, _)) in enumerate(edges) {
            out += "\"\(String(node))\":\"\(names[node]!)\""
            if index != edges.count - 1 {
                out += ","
            }
        }
        out += "}"
        out += "}"
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
        names[id] = andName
        if nodes[id] == nil {
            nodes[id] = andName
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
        if node == toNode { // Never add self-edges.
            return
        }
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
        let addGenders:(NSData?, NSURLResponse?, NSError?) -> Void = {
            (data:NSData?, response:NSURLResponse?, error:NSError?) in
            if error == nil && data != nil {
                var parsingError:NSError? = NSError()
                let rawGenderData:AnyObject? = NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions(0), error: &parsingError)
                if rawGenderData == nil {
                    return
                }
                if let genderData = rawGenderData as? [String : AnyObject] {
                    for (firstName:String, genderIndicator:AnyObject) in genderData {
                        let gender = Gender.fromString(genderIndicator.description!)
                        self.genders[firstName] = gender
                        if gender != Gender.Undetermined && SocialGraphController.sharedInstance.managedObjectContext != nil {
                            GenderData.insert(SocialGraphController.sharedInstance.managedObjectContext!, name: firstName, gender: gender)
                        }
                    }
                    if SocialGraphController.sharedInstance.managedObjectContext != nil {
                        SocialGraphController.sharedInstance.managedObjectContext!.save(nil)
                    }
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
            if gender == Gender.Undetermined && isUTF8Compatible(firstName) {
                requestURL += "\(firstName),"
            }
        }
        if genders.count > 0 {
            requestURL = requestURL.substringToIndex(requestURL.endIndex.predecessor()) // Remove the trailing ampersand.
            getRequestToURL(requestURL, addGenders)
        }
    }

    /**
     * Attempts to load gender data from cache. Will only perform this action once.
     */
    public func loadGendersFromCoreData() {
        if !didLoadGendersFromCache {
            updateFirstNames()
            if SocialGraphController.sharedInstance.managedObjectContext != nil {
                let cachedGenders:[GenderData] = GenderData.allObjects(SocialGraphController.sharedInstance.managedObjectContext!)
                for genderData in cachedGenders {
                    genders[genderData.firstName] = genderData.gender()
                }
                didLoadGendersFromCache = true
            }
        }
    }

    /**
     * Takes all names that appear as values in self.names and extracts first names. Then
     * adds each first name to self.genders, if it is not already present. New first names
     * are initially mapped to Gender.Undetermined.
     */
    private func updateFirstNames() {
        for (id:UInt64, fullName:String) in self.nodes {
            let firstName:String = firstNameFromFullName(fullName)
            if genders[firstName] == nil {
                genders[firstName] = Gender.Undetermined
            }
        }
    }

    /**
     * Compute and store the median edge weight.
     * TODO Maybe automatically update the median edge weight on the
     * fly whenever a new edge is added or an edge is removed?
     */
    public func updateMedianEdgeWeight() {
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
                            nameDictionary[base64Node] = self.nodes[node]
                        }
                        if nameDictionary[base64Neighbor] == nil {
                            nameDictionary[base64Neighbor] = self.nodes[neighbor]
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

    // MARK: - Random walk functions and subroutines

    /**
     * Shortcut for finding the gender given user ID. Uses the graph's data structures
     * to map ID -> name -> first name -> gender. Returns Gender.Undetermined if ID
     * lookup failed.
     */
    public func genderFromId(id:UInt64) -> Gender {
        if let name:String = nodes[id] {
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
        for (id:UInt64, name:String) in nodes {
            if id == root {
                continue
            }
            let gender:Gender = genderFromId(id)
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
    var nodes:[UInt64:String]
    var genders:[String:Gender]
    var currentSample:[UInt64]
    // Unlike nodes, names does not reflect the graph topology. Operations such as pruning do not affect names.
    var names:[UInt64:String]

    // Edge-based metadata for computing heuristics.
    var totalEdgeWeight:Float
    var edgeCount:Int
    var totalEdgeWeightFromRoot:Float

    // Match graph used to improve heuristics.
    var walkWeightMultipliers:[UInt64:Float]

    // Miscellaneous state variables.
    var isCurrentlyUpdatingGender:Bool
    var shouldReupdateGender:Bool
    var didLoadGendersFromCache:Bool
    var medianEdgeWeight:Float? = nil

    // For thread safety.
    var genderUpdateSemaphore = dispatch_semaphore_create(1)
}
