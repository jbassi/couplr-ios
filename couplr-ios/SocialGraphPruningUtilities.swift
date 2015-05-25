//
//  GraphPruningUtilities.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 3/29/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

extension SocialGraph {
    
    /**
     * Iterate through all edges in the graph and remove edges
     * that have a weight less than a minimum threshold.
     */
    public func pruneGraphByMinWeightThreshold(minWeight:Float = kMinGraphEdgeWeight) {
        // Collect a list of undirected edges that should be removed.
        var edgesToRemove:[(UInt64, UInt64)] = []
        for (node:UInt64, neighbors:[UInt64:Float]) in edges {
            for (neighbor:UInt64, weight:Float) in edges[node]! {
                if node < neighbor && weight < minWeight {
                    edgesToRemove.append((node, neighbor))
                }
            }
        }
        pruneEdgesFromGraph(edgesToRemove, andRemoveIsolatedNodes: true)
    }
    
    /**
     * Removes all edges from the graph that are only connected via a single
     * edge to the root user.
     */
    public func pruneGraphByIsolationFromRoot() {
        var edgesToRemove:[(UInt64, UInt64)] = Array(edges[root]!.keys.filter({
            (neighbor:UInt64) -> Bool in
            return self.edges[neighbor]!.count == 1
        }).map({
            (neighbor:UInt64) -> (UInt64, UInt64) in
            return (neighbor, self.root)
        }))
        pruneEdgesFromGraph(edgesToRemove, andRemoveIsolatedNodes: false)
    }
    
    /**
     * Prunes a list of edges specified by a list of tuples (u, v) from the
     * graph and then removes all isolated nodes.
     */
    private func pruneEdgesFromGraph(edgesToRemove:[(UInt64, UInt64)], andRemoveIsolatedNodes:Bool) {
        // Remove the undirected edges.
        for (src:UInt64, dst:UInt64) in edgesToRemove {
            disconnectNode(src, fromNode: dst)
        }
        // Remove fully disconnected nodes.
        if andRemoveIsolatedNodes {
            var nodesToRemove:[UInt64] = []
            for node:UInt64 in nodes.keys {
                if edges[node] == nil {
                    nodesToRemove.append(node)
                }
            }
            for node:UInt64 in nodesToRemove {
                nodes[node] = nil
            }
        }
    }
}
