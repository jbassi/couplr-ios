//
//  GraphStorage.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 1/11/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import CoreData

@objc(RootData)
/**
 * Stores the id of the root user.
 */
public class RootData: NSManagedObject {
    
    @NSManaged var idBase64:String
    @NSManaged var timestamp:NSDate
    
    public func id() -> UInt64 {
        return decodeBase64(idBase64)
    }
    
    public func set(id:UInt64, timestamp:NSDate) {
        self.idBase64 = encodeBase64(id)
        self.timestamp = timestamp
    }
    
    public func toString() -> String {
        return "Root(id=\(id()), time=\"\(timestamp.description)\")"
    }
    
    class func insert(context:NSManagedObjectContext, id:UInt64, timestamp:NSDate) {
        let root = NSEntityDescription.insertNewObjectForEntityForName("RootData", inManagedObjectContext: context) as RootData
        root.set(id, timestamp: timestamp)
    }
    
    class func allObjects(context:NSManagedObjectContext) -> [RootData] {
        let request = NSFetchRequest(entityName: "RootData")
        var error:NSError? = nil
        if let fetchResults = context.executeFetchRequest(request, error: &error) as? [RootData] {
            return fetchResults
        }
        log("Could not fetch local root with error \"\(error?.description)\"", withFlag: "-")
        return []
    }
}

@objc(NodeData)
/**
 * Stores an (id, name) pairing for one of the nodes in the
 * social graph.
 */
public class NodeData: NSManagedObject {
    
    @NSManaged var idBase64:String
    @NSManaged var name:String
    
    public func id() -> UInt64 {
        return decodeBase64(idBase64)
    }
    
    public func set(id:UInt64, name:String) {
        self.name = name
        self.idBase64 = encodeBase64(id)
    }

    public func toString() -> String {
        return "Node(id=\(id()), name=\"\(name)\")"
    }
    
    class func insert(context:NSManagedObjectContext, id:UInt64, name:String) {
        let node:NodeData = NSEntityDescription.insertNewObjectForEntityForName("NodeData", inManagedObjectContext: context) as NodeData
        node.set(id, name: name)
    }
    
    class func allObjects(context:NSManagedObjectContext) -> [NodeData] {
        let request = NSFetchRequest(entityName: "NodeData")
        var error:NSError? = nil
        if let fetchResults = context.executeFetchRequest(request, error: &error) as? [NodeData] {
            return fetchResults
        }
        log("Could not fetch local nodes with error \"\(error?.description)\"", withFlag: "-")
        return []
    }
}

@objc(EdgeData)
/*
 * Stores information for a weighted undirected edge between
 * two users in the social graph.
 */
public class EdgeData: NSManagedObject {
    
    @NSManaged var fromBase64:String
    @NSManaged var toBase64:String
    @NSManaged var weight:Float
    
    public func from() -> UInt64 {
        return decodeBase64(fromBase64)
    }
    
    public func to() -> UInt64 {
        return decodeBase64(toBase64)
    }
    
    public func set(from:UInt64, to:UInt64, weight:Float) {
        self.fromBase64 = encodeBase64(from)
        self.toBase64 = encodeBase64(to)
        self.weight = weight
    }
    
    public func toString() -> String {
        return "Edge(to=\(from), from=\(to()), weight=\(weight))"
    }
    
    class func insert(context:NSManagedObjectContext, from:UInt64, to:UInt64, weight:Float) {
        let edge:EdgeData = NSEntityDescription.insertNewObjectForEntityForName("EdgeData", inManagedObjectContext: context) as EdgeData
        edge.set(from, to: to, weight: weight)
    }
    
    class func allObjects(context:NSManagedObjectContext) -> [EdgeData] {
        let request = NSFetchRequest(entityName: "EdgeData")
        var error:NSError? = nil
        if let fetchResults = context.executeFetchRequest(request, error: &error) as? [EdgeData] {
            return fetchResults
        }
        log("Could not fetch local edges with error \"\(error?.description)\"", withFlag: "-")
        return []
    }
}
