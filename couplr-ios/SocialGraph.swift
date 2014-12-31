
/**
 * Represents a user's social graph derived from scraping Facebook data.
 */
class SocialGraph {
    
    /**
     * Initializes an empty graph rooted at a given user with a mapping from
     * user ID.
     */
    init(root:UInt64, names:[UInt64:String]) {
        self.root = root
        self.names = names
        self.edges = [UInt64:[UInt64:Float]]()
        self.directedTotalWeight = 0
        self.directedEdgeCount = 0
    }

    /**
     * Adds an undirected edge between two users, implemented as two directed
     * edges in reverse directions. Using connectNode to modify the graph will
     * enforce symmetry.
     */
    func connectNode(node:UInt64, toNode:UInt64, withWeight:Float = 1) {
        addEdgeFrom(node, toNode:toNode, withWeight:withWeight)
        addEdgeFrom(toNode, toNode:node, withWeight:withWeight)
    }

    /**
     * Removes all edges between two users. Using disconnectNode to modify the
     * graph will enforce symmetry.
     */
    func disconnectNode(node:UInt64, fromNode:UInt64) {
        removeEdgeFrom(node, toNode:fromNode)
        removeEdgeFrom(fromNode, toNode:node)
    }
    
    /**
     * Samples some number of users by performing a weighted random walk on the graph
     * starting at the root user.
     */
    func randomSample(size:Int = kRandomSampleCount) -> [UInt64:String] {
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
     * Computes the sampling weight of an edge using a sigmoid function with range
     * between 0 and withLimit.
     */
    func sampleWeightForEdgeWeight(weight:Float, withLimit:Float = kSamplingWeightLimit) -> Float {
        return withLimit / (1.0 + exp(-weight))
    }
    
    /**
     * Randomly samples a node in the graph.
     * TODO Add gendered bias.
     */
    func sampleRandomNode(withNodesTraversed:[UInt64:String]) -> UInt64 {
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
    func takeRandomStepFrom(currentNode:UInt64, withNodesTraversed:[UInt64:String]) -> UInt64 {
        var possibleNextNodes:[(UInt64, Float)] = [(UInt64, Float)]()
        for (neighbor:UInt64, weight:Float) in self.edges[currentNode]! {
            if withNodesTraversed[neighbor] != nil {
                continue
            }
            possibleNextNodes.append((neighbor, sampleWeightForEdgeWeight(weight)))
        }
        return weightedRandomSample(possibleNextNodes)
    }

    /**
     * Adds a directed edge with specified weight between two users. Does
     * not check for self-edges. If an edge already exists between the users,
     * increments the current weight of the edge.
     * In general, you should not be adding directed edges to the social graph.
     * Instead, use connectNode to update the graph.
     */
    func addEdgeFrom(node:UInt64, toNode:UInt64, withWeight:Float = 1) {
        if edges[node] == nil {
            edges[node] = [UInt64:Float]()
            directedEdgeCount++
        }
        edges[node]![toNode] = weightFrom(node, toNode:toNode) + withWeight
        directedTotalWeight += withWeight
    }

    /**
     * Removes an edge connecting one node to another, if any. In general,
     * you should not be removing directed edges from the social graph.
     * Instead, use disconnectNode to update the graph.
     */
    func removeEdgeFrom(node:UInt64, toNode:UInt64) {
        if edges[node] != nil && edges[node]![toNode] != nil {
            directedEdgeCount--
            directedTotalWeight -= edges[node]![toNode]!
            edges[node]![toNode] = nil
        }
    }

    /**
     * Returns the connection weight between two given nodes.
     */
    func weightFrom(node:UInt64, toNode:UInt64) -> Float {
        return (edges[node] == nil || edges[node]![toNode] == nil) ? kUnconnectedEdgeWeight : edges[node]![toNode]!
    }

    /**
     * Returns the connection weight between two given nodes.
     */
    subscript(node:UInt64, toNode:UInt64) -> Float {
        return weightFrom(node, toNode:toNode)
    }

    /**
     * Returns a string representation of this graph, displaying its edges.
     */
    func toString() -> String {
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

    var root:UInt64
    var edges:[UInt64:[UInt64:Float]]
    var names:[UInt64:String]
    var directedEdgeCount:Int
    var directedTotalWeight:Float
}
