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
 * Extracts a Float from an AnyObject.
 * 
 * TODO This is also a hack.
 */
func floatFromAnyObject(anyObject:AnyObject!) -> Float {
    let floatNSStr:NSString = NSString(string:anyObject.description)
    return floatNSStr.floatValue
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
 * Returns shortened versions of a full name, using initials instead
 * of the full word.
 */
func shortenFullName(name:String, useMiddleInitial:Bool, useLastInitial:Bool) -> String {
    var words:[String] = split(name) {$0 == " "}
    if useMiddleInitial && words.count > 2 {
        if words.count > 3 || words[1].utf16Count > 2 {
            let char:Character = words[1][words[1].startIndex]
            words[1] = String(char).uppercaseString + "."
        }
        for index in 2..<words.count - 1 {
            words[index] = ""
        }
    }
    if useLastInitial {
        var lastNameString:String = words.last!
        if lastNameString.utf16Count > 2 {
            let char:Character = lastNameString[lastNameString.startIndex]
            lastNameString = String(char).uppercaseString + "."
        }
        words[words.count - 1] = lastNameString
    }
    return " ".join(words)
}

/**
 * Prints log messages for debugging.
 */
func log(message:String, withIndent:Int = 0, withNewline:Bool = true, withFlag:Character = "+") {
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

/**
 * Serialize an unsigned long long as a binary string in UTF8.
 */
func binaryStringFromUInt64(value:UInt64) -> String {
    var result:[Character] = []
    var temp:UInt64 = value
    result.reserveCapacity(8)
    for index in 0..<8 {
        let num:Int = Int(value & 0xFF)
        result.append(Character(UnicodeScalar(num)))
        temp = temp >> 8
    }
    return "".join(result.map({String($0)}))
}

/**
 * Deserialize a UTF8 string as an unsigned long long.
 */
func uint64FromBinaryString(string:String) -> UInt64 {
    let values = string.unicodeScalars
    var cursor = values.endIndex.predecessor()
    var result:UInt64 = 0
    for i in 0..<8 {
        let chr = values[cursor]
        result = (result << 8) + UInt64(chr.value)
        if i != 7 {
            cursor = cursor.predecessor()
        }
    }
    return result
}