//
//  SocialGraph.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 12/26/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

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
        self.pictureURLs = [UInt64:String]()
        self.directedTotalWeight = 0
        self.directedEdgeCount = 0
        self.genders = [String:Gender]()
        for (id:UInt64, fullName:String) in self.names {
            let firstName:String = fullName.substringToIndex(fullName.rangeOfString(" ")!.startIndex)
            self.genders[firstName] = Gender.Undetermined
        }
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
        out += "    edge count   : \(directedEdgeCount/2)\n"
        out += "    total weight : \(directedTotalWeight/2)\n\n"
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
     * Load a map from first name to gender using the first names encountered
     * in the graph. Sends a request for each first name for which gender is
     * currently unknown. Initially, the gender dictionary maps all first names
     * to Gender.Undetermined.
     */
    public func updateGenders() {
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
//                for index in 0...10 {
//                    println(self.randomSample())
//                    println()
//                }
//                println("<<<<<<< Random samples after gender bias")
            }
        }
        var requestURL:String = kGenderResolverURL
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
     * Adds an undirected edge between two users, implemented as two directed
     * edges in reverse directions. Using connectNode to modify the graph will
     * enforce symmetry.
     */
    public func connectNode(node:UInt64, toNode:UInt64, withWeight:Float = 1) {
        addEdgeFrom(node, toNode:toNode, withWeight:withWeight)
        addEdgeFrom(toNode, toNode:node, withWeight:withWeight)
    }

    /**
     * Removes all edges between two users. Using disconnectNode to modify the
     * graph will enforce symmetry.
     */
    public func disconnectNode(node:UInt64, fromNode:UInt64) {
        removeEdgeFrom(node, toNode:fromNode)
        removeEdgeFrom(fromNode, toNode:node)
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
            nextStep = takeRandomStepFrom(nextStep, withNodesTraversed:sample)
        }
        sample[root] = nil
        return sample
    }

    /**
     * Shortcut for finding the gender given user ID. Uses the graph's data structures to map
     * ID -> name -> first name -> gender. Returns Gender.Undetermined if ID lookup failed.
     */
    private func genderFromID(id:UInt64) -> Gender {
        if let name:String = names[id] {
            let firstName:String = name.substringToIndex(name.rangeOfString(" ")!.startIndex)
            return genders[firstName] == nil ? Gender.Undetermined : genders[firstName]!
        }
        return Gender.Undetermined
    }

    /**
     * Computes the score of a potential next hop node from a given current node. Examines
     * the current gender ratio of nodes traversed as well as the edge weight to help determine
     * this score. If the next hop node is not even connected, returns a kUnconnectedEdgeWeight.
     */
    private func scoreFrom(node:UInt64, toNextHop:UInt64, withGenderRatio:(m:Float, f:Float)) -> Float {
        let edgeWeight:Float = weightFrom(node, toNode:toNextHop)
        let nextHopGender:Gender = genderFromID(toNextHop)
        switch nextHopGender {
        case .Undetermined:
            return edgeWeight
        case .Male:
            return edgeWeight + (kGenderBiasCoefficient * (2 * withGenderRatio.1 - 1))
        case .Female:
            return edgeWeight + (kGenderBiasCoefficient * (2 * withGenderRatio.0 - 1))
        }
    }

    /**
     * Returns the ratio of known male and females in a set of nodes. Skips over Undetermined
     * genders as well as the root node (i.e. they are simply not counted as male or female).
     * The output will sum to 1. If no known males or females were encountered, the output
     * defaults to (0.5, 0.5)
     */
    private func genderRatio(nodesTraversed:[UInt64:String]) -> (Float, Float) {
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
        return withLimit / (1.0 + exp(-score))
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
        let ratio:(Float, Float) = genderRatio(withNodesTraversed)
        for (neighbor:UInt64, weight:Float) in self.edges[node]! {
            if withNodesTraversed[neighbor] != nil {
                continue
            }
            let neighborScore:Float = scoreFrom(node, toNextHop:neighbor, withGenderRatio:ratio)
            let sampleWeight:Float = sampleWeightForScore(neighborScore)
            possibleNextNodes.append((neighbor, sampleWeight))
        }
//        println("Currently @\(self.names[node]!)")
//        println("Gender ratio: [m=\(ratio.0)), f=\(ratio.1)]")
//        println("Next possible nodes: [")
//        for (id:UInt64, weight:Float) in possibleNextNodes {
//            println("    w(\(self.names[id]!)) = \(weight)")
//        }
//        println("]")
        return weightedRandomSample(possibleNextNodes)
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
            directedEdgeCount++
        }
        var currentWeight:Float = weightFrom(node, toNode:toNode)
        if currentWeight <= kUnconnectedEdgeWeight {
            currentWeight = 0
        }
        edges[node]![toNode] = currentWeight + withWeight
        directedTotalWeight += withWeight
    }

    /**
     * Removes an edge connecting one node to another, if any. In general,
     * you should not be removing directed edges from the social graph.
     * Instead, use disconnectNode to update the graph.
     */
    private func removeEdgeFrom(node:UInt64, toNode:UInt64) {
        if edges[node] != nil && edges[node]![toNode] != nil {
            directedEdgeCount--
            directedTotalWeight -= edges[node]![toNode]!
            edges[node]![toNode] = nil
        }
    }

    /**
     * Returns the connection weight between two given nodes.
     */
    private func weightFrom(node:UInt64, toNode:UInt64) -> Float {
        return (edges[node] == nil || edges[node]![toNode] == nil) ? kUnconnectedEdgeWeight : edges[node]![toNode]!
    }

    var root:UInt64
    var edges:[UInt64:[UInt64:Float]]
    var names:[UInt64:String]
    var genders:[String:Gender]
    var pictureURLs:[UInt64:String]
    var directedEdgeCount:Int
    var directedTotalWeight:Float
}