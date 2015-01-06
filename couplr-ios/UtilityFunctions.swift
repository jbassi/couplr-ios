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

func randomFloat() -> Float {
    return Float(arc4random()) / Float(UINT32_MAX)
}

func parseArrayFromJSONData(inputData: NSData) -> Array<NSDictionary> {
    var error: NSError?
    var boardsDictionary = NSJSONSerialization.JSONObjectWithData(inputData, options: NSJSONReadingOptions.MutableContainers, error: &error) as Array<NSDictionary>
    return boardsDictionary
}

func profilePictureURLFromID(id:UInt64, withWidth:Int = 200, withHeight:Int = 200) -> String {
    return "\(kFBGraphURLPrefix)\(id)/picture?width=\(withWidth)&height=\(withHeight)"
}

func firstNameFromFullName(fullName:String) -> String {
    return fullName.substringToIndex(fullName.rangeOfString(" ")!.startIndex)
}

func sampleWithoutReplacement(var list:[UInt64], count:Int) -> [UInt64] {
    var result:[UInt64] = [UInt64]()
    for sampleNum:Int in 0..<count {
        let sampleIndex:Int = sampleNum + randomInt(list.count - sampleNum)
        let tempValue:UInt64 = list[sampleNum]
        list[sampleNum] = list[sampleIndex]
        list[sampleIndex] = tempValue
        result.append(list[sampleNum])
    }
    return result
}

/**
 * Extracts an Int from an AnyObject.
 *
 * TODO This is god-awful, we'll need to find a safer way to implement this.
 */
func uint64FromAnyObject(anyObject:AnyObject!) -> UInt64 {
    let numNSStr:NSString = NSString(string:anyObject.description)
    return UInt64(numNSStr.longLongValue)
}

/**
 * Sends a GET request to the specified URL and fires the given callback
 * when a response is received.
 */
func getRequestToURL(url:String, callback:(NSData?, NSURLResponse?, NSError?) -> Void) -> Void {
    let nsurl = NSURL(string: url)
    let task = NSURLSession.sharedSession().dataTaskWithURL(nsurl!) {
        (data:NSData?, response:NSURLResponse?, error:NSError?) in
        callback(data, response, error)
    }
    task.resume()
}

/**
 * Returns a random positive integer LESS THAN a given upper
 * bound.
 */
func randomInt(withUpperbound:Int) -> Int {
    return Int(floorf(randomFloat() * (Float(withUpperbound))))
}

/**
 * Returns a randomly sampled node given a list of sampling weights. If
 * the list elements to sample is empty, returns a default value of 0.
 * TODO This is a naive implementation. Make me faster!
 */
func weightedRandomSample(elements:[(UInt64, Float)]) -> UInt64 {
    if elements.count == 0 {
        return 0
    }
    var total:Float = 0
    for (node:UInt64, value:Float) in elements {
        total += value
    }
    var sampleTarget:Float = total * randomFloat()
    var (result:UInt64, temp:Float) = elements[0]
    for index:Int in 0..<elements.count {
        let (node:UInt64, value:Float) = elements[index]
        result = node
        sampleTarget -= value
        if sampleTarget <= 0 {
            break
        }
    }
    return result
}

/**
 * Prints log messages for debugging.
 */
func log(message:String, withIndent:Int = 0, withNewline:Bool = true, withFlag:Character = "+") -> Void {
    if !kOutputLogMessages {
        return
    }
    var spacing:String = " "
    for i:Int in 0..<withIndent {
        spacing += "    "
    }
    if withNewline {
        println("[\(withFlag)]\(spacing)\(message)")
    } else {
        print("[\(withFlag)]\(spacing)\(message)")
    }
}
