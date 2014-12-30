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

func testFriendList() {
    var friendsRequest : FBRequest = FBRequest.requestForMyFriends()
    friendsRequest.startWithCompletionHandler{(connection:FBRequestConnection!, result:AnyObject!, error:NSError!) -> Void in
        var resultdict = result as NSDictionary
        println("Result Dict: \(resultdict)")
        var data : NSArray = resultdict.objectForKey("data") as NSArray
    }
}

func testGETRequest() {
    let url = NSURL(string: "https://graph.facebook.com/me/friends?access_token=CAACEdEose0cBAERCh5lCtu57Toam4vfY3aW9SzaT69g27pMxbsFqZB5lnGLZBsWMQsn2Gz9De4Sf3AXZARHRuNbBXWsTf93qdy6yPKsb9UVZCsOBhlpmZAOieUmaiPYoWVFhtv7CpYakZBKc4cJPBXeNAcOXN3ZBZBQoVk8ZCHdDggUZBtOd8wZAITMO4WP8ERkC9mvgUdZBsElAF9ZAZBzoou1Q7tpHKChXUhJOAZD")
    
    let task = NSURLSession.sharedSession().dataTaskWithURL(url!) {(data, response, error) in
        println(NSString(data: data, encoding: NSUTF8StringEncoding))
    }
    
    task.resume()
}