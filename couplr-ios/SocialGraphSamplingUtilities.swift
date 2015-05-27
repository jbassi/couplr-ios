//
//  GraphSamplingUtilities.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 3/29/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

extension SocialGraph {
    /**
     * Samples some number of users by performing a weighted random walk on the
     * graph starting at the root user.
     */
    public func updateRandomSample(size: Int = kRandomSampleCount, keepUsersAtIndices: [(UInt64, Int)] = []) {
        if size - keepUsersAtIndices.count <= 0 {
            return
        }
        currentSample = randomWalkSample(size, keepUsers: Array(keepUsersAtIndices.map{ $0.0 }))
        for (keepUserId: UInt64, atIndex: Int) in keepUsersAtIndices {
            for (index: Int, userId: UInt64) in enumerate(currentSample) {
                if userId == keepUserId {
                    currentSample[index] = currentSample[atIndex]
                    currentSample[atIndex] = keepUserId
                }
            }
        }
        if kShowRandomWalkDebugOutput {
            println("    Done. Final random walk result...")
            for id: UInt64 in currentSample {
                println("        \(names[id]!) (\(id))")
            }
            println()
        }
        updateWalkWeightMultipliers()
    }
    
    private func randomWalkSample(size: Int, expectedNumRandomHops: Float = kExpectedNumRandomHops, keepUsers: [UInt64] = []) -> [UInt64] {
        let randomHopProbability: Float = expectedNumRandomHops / Float(size - 1)
        var samples: [UInt64: Bool] = [UInt64: Bool]()
        for userId in keepUsers {
            samples[userId] = true
        }
        var nextStep: UInt64 = root
        while samples.count < size {
            if nextStep != root && randomFloat() < randomHopProbability {
                let currentStep = nextStep
                nextStep = sampleRandomNode(samples)
                if kShowRandomWalkDebugOutput {
                    println("    [\(samples.count + 1)] Randomly hopping from \(names[currentStep]!) to \(names[nextStep]!)")
                }
            } else {
                nextStep = takeRandomStepFrom(nextStep, withNodesTraversed: samples)
                if nextStep == 0 { // Random walk reached a dead end.
                    nextStep = sampleRandomNode(samples)
                }
            }
            samples[nextStep] = true
        }
        return Array(samples.keys)
    }
    
    /**
     * Given a current node and a list of nodes previously traversed, randomly jumps
     * to a new neighboring node that does not already appear in the list of previous
     * nodes and is not the root. If there is no such node, returns 0.
     */
    private func takeRandomStepFrom(node: UInt64, withNodesTraversed: [UInt64: Bool]) -> UInt64 {
        var possibleNextNodes: [(UInt64, Float)] = [(UInt64, Float)]()
        var originalNormalizedWeights: [Float] = [Float]() // Debugging purposes.
        let currentGender: Gender = node == root ? Gender.Undetermined : genderFromId(node)
        var sameGenderScoreSum: Float = 0
        var differentGenderScoreSum: Float = 0
        let meanNonRootWeight: Float = baselineEdgeWeight()
        // Compute sampling weights prior to gender renormalization.
        for (neighbor: UInt64, weight: Float) in self.edges[node]! {
            if neighbor == root || withNodesTraversed[neighbor] != nil {
                continue
            }
            let neighborScore: Float = sampleWeightForScore(weight - meanNonRootWeight)
            possibleNextNodes.append((neighbor, neighborScore))
            originalNormalizedWeights.append(weight - meanNonRootWeight)
            let gender: Gender = genderFromId(neighbor)
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
            let newSameGenderScoreSum: Float = (sameGenderScoreSum + differentGenderScoreSum) / Float(1 + kGenderBiasRatio)
            let newDifferentGenderScoreSum: Float = kGenderBiasRatio * newSameGenderScoreSum
            for index in 0..<possibleNextNodes.count {
                let (neighbor: UInt64, weight: Float) = possibleNextNodes[index]
                let gender: Gender = genderFromId(neighbor)
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
            let (neighbor: UInt64, weight: Float) = possibleNextNodes[index]
            possibleNextNodes[index].1 *= 1.0 + walkWeightBonusForNode(neighbor)
        }
        if kShowRandomWalkDebugOutput {
            if withNodesTraversed.count == 0 {
                println("[!] Beginning random walk...")
            }
            print("    [\(withNodesTraversed.count + 1)] Now at \(nodes[node]!) (\(genderFromId(node).toString()))\n")
            if possibleNextNodes.count == 0 {
                println("        No unvisited neighbors to step to!")
            } else {
                var total: Float = 0
                for (id: UInt64, weight: Float) in possibleNextNodes {
                    total += weight
                }
                for index: Int in 0..<possibleNextNodes.count {
                    let (neighbor: UInt64, weight: Float) = possibleNextNodes[index]
                    let percentage: Double = Double(100.0 * (weight/total))
                    var percentageAsString: String
                    if percentage < 10.0 {
                        percentageAsString = String(format: "%.3f", percentage)
                    } else if percentage < 100.0 {
                        percentageAsString = String(format: "%.2f", percentage)
                    } else {
                        percentageAsString = String(format: "%.1f", percentage)
                    }
                    let multiplierAsString = String(format: "%.2f", walkWeightBonusForNode(neighbor))
                    let weightAsString: String = String(format: "%.2f", originalNormalizedWeights[index])
                    var nameAsPaddedString: String = nodes[neighbor]!
                    if nameAsPaddedString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding) < 30 {
                        for index in nameAsPaddedString.lengthOfBytesUsingEncoding(NSUTF8StringEncoding)..<30 {
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
    public func walkWeightBonusForNode(id: UInt64) -> Float {
        return walkWeightMultipliers[id] == nil ? 0 : walkWeightMultipliers[id]!
    }
    
    /**
     * Update walk weight multipliers. This means decaying all existing multipliers and
     * applying a penalty to all nodes chosen in the current random sample.
     */
    private func updateWalkWeightMultipliers() {
        for (node: UInt64, multiplier: Float) in walkWeightMultipliers {
            walkWeightMultipliers[node] = kWalkWeightDecayRate * multiplier
        }
        for node: UInt64 in currentSample {
            walkWeightMultipliers[node] = max(-0.99, walkWeightBonusForNode(node) - kWalkWeightPenalty)
        }
        // Clean the walk weight multipliers dictionary.
        var nodesToRemove: [UInt64] = []
        for (node: UInt64, multiplier: Float) in walkWeightMultipliers {
            if abs(multiplier) < 0.1 {
                nodesToRemove.append(node)
            }
        }
        for node: UInt64 in nodesToRemove {
            walkWeightMultipliers[node] = nil
        }
    }
    
    /**
     * Computes the sampling weight of an edge using a sigmoid function with range
     * between 0 and withLimit.
     */
    private func sampleWeightForScore(score: Float, withLimit: Float = kSamplingWeightLimit) -> Float {
        return withLimit / (1.0 + pow(kSigmoidExponentialBase, -score))
    }
    
    /**
     * Randomly samples a node out of the root user's neighbors.
     */
    private func sampleRandomNode(withNodesTraversed: [UInt64: Bool]) -> UInt64 {
        var possibleNextNodes: [UInt64] = Array(edges[root]!.keys.filter { (neighbor: UInt64) -> Bool in
            return withNodesTraversed[neighbor] == nil
        })
        if possibleNextNodes.count == 0 {
            possibleNextNodes = Array(nodes.keys.filter { (neighbor: UInt64) -> Bool in
                return withNodesTraversed[neighbor] == nil && neighbor != self.root
            })
        }
        return possibleNextNodes[randomInt(possibleNextNodes.count)]
    }
    
    /**
     * Computes the baseline average weight for the nodes. This
     * is the mean weight of edges, not including those connecting
     * root nodes.
     */
    public func baselineEdgeWeight() -> Float {
        if medianEdgeWeight != nil {
            return medianEdgeWeight!
        }
        if edgeCount == 0 {
            return 0
        }
        let numEdgesFromRoot = edges[root] == nil ? 0 : edges[root]!.count
        return (totalEdgeWeight - totalEdgeWeightFromRoot) / Float(edgeCount - numEdgesFromRoot)
    }
}
