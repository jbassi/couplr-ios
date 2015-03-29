//
//  UtilityFunctions.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/28/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit
import Dispatch

public enum NameDisplayMode {
    case Full, MiddleInitial, LastInitialNoMiddle
}

func timeElapsedAsText(timeInterval:NSTimeInterval) -> String {
    if timeInterval < 60 {
        return "A moment"
    } else if timeInterval >= 31536000 {
        return "An eternity"
    } else {
        var value:Int = 0
        var unit:String = ""
        if timeInterval < 3600 {
            value = Int(round(timeInterval / 60))
            unit = "minute"
        } else if timeInterval < 86400 {
            value = Int(round(timeInterval / 3600))
            unit = "hour"
        } else if timeInterval < 2592000 {
            value = Int(round(timeInterval / 86400))
            unit = "day"
        } else {
            value = Int(round(timeInterval / 2592000))
            unit = "month"
        }
        return value == 1 ? "1 \(unit)" : "\(value) \(unit)s"
    }
}

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

func profilePictureURLFromId(id:UInt64, withWidth:Int = 200, withHeight:Int = 200) -> NSURL {
    return NSURL(string: "\(kFBGraphURLPrefix)\(id)/picture?width=\(withWidth)&height=\(withHeight)")!
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
func uint64FromAnyObject(anyObject:AnyObject!, base64:Bool = false) -> UInt64 {
    if base64 {
        return decodeBase64(anyObject.description)
    }
    let numNSStr:NSString = NSString(string: anyObject.description)
    return UInt64(numNSStr.longLongValue)
}

/**
 * Extracts a Float from an AnyObject.
 *
 * TODO This is also a hack.
 */
func floatFromAnyObject(anyObject:AnyObject!) -> Float {
    let floatNSStr:NSString = NSString(string: anyObject.description)
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
 * Returns a specified version of a name given the full name. The Full
 * display mode simply returns the original string. The MiddleInitial
 * mode drops everything but the first word of the middle name if it is
 * at least 2 characters and otherwise uses the first initial of the 
 * first word of the middle name. LastInitialNoMiddle ignores the middle
 * name entirely and uses only the last initial of the last name, or the
 * full last name if it is two characters or less.
 */
func shortenFullName(name:String, mode:NameDisplayMode) -> String {
    var words:[String] = split(name) {$0 == " "}
    switch (mode) {
    case .Full:
        return name
        
    case .MiddleInitial:
        if words.count > 2 {
            if words.count > 3 || words[1].utf16Count > 2 {
                let char:Character = words[1][words[1].startIndex]
                words[1] = String(char).uppercaseString + "."
            }
            for index in 2..<words.count - 1 {
                words[index] = ""
            }
        }
        break

    case .LastInitialNoMiddle:
        if words.count > 1 {
            var lastNameString:String = words.last!
            if lastNameString.utf16Count > 2 {
                let char:Character = lastNameString[lastNameString.startIndex]
                lastNameString = String(char).uppercaseString + "."
            }
            words[words.count - 1] = lastNameString
            while words.count > 2 {
                words.removeAtIndex(1)
            }
            break
        }
    }
    return " ".join(words)
}

/**
 * Prints log messages for debugging.
 */
func log(message:String, withIndent:Int = 0, withNewline:Bool = false, withFlag:Character = "+") {
    if !kOutputLogMessages {
        return
    }
    var spacing:String = " "
    for i:Int in 0..<withIndent {
        spacing += "    "
    }
    if withNewline {
        println("[\(withFlag)]\(spacing)\(message)\n")
    } else {
        println("[\(withFlag)]\(spacing)\(message)")
    }
}

/**
 * Extracts a user ID and a name from an object that contains
 * both (e.g. a Facebook "from" object).
 */
func idAndNameFromObject(object:AnyObject) -> (UInt64, String) {
    let nameObject:AnyObject! = object["name"]!
    let name:String = nameObject.description
    let idObject:AnyObject? = object["id"]
    if idObject != nil {
        let id:UInt64 = uint64FromAnyObject(idObject!)
        return (id, name)
    }
    return (0, name)
}

/**
 * Fetches the current time in seconds since 1970.
 */
func currentTimeInSeconds() -> Double {
    let t:NSDate = NSDate()
    return t.timeIntervalSince1970
}

/**
 * Serialize an unsigned long long as a base 64 string.
 *
 * TODO Last time I tried all 256, Parse didn't seem to store
 * the data properly. Try this again sometime?
 */
func encodeBase64(value:UInt64) -> String {
    var result:[Character] = []
    var temp:UInt64 = value
    result.reserveCapacity(11)
    for index in 0..<11 {
        let num:Int = Int(temp & 0x3F)
        result.append(Character(UnicodeScalar(num + 48)))
        temp = temp >> 6
    }
    return "".join(result.map({String($0)}))
}

/**
 * Deserialize a string as an unsigned long long.
 */
func decodeBase64(string:String) -> UInt64 {
    let values = string.unicodeScalars
    var cursor = values.endIndex.predecessor()
    var result:UInt64 = 0
    for i in 0..<11 {
        let chr = values[cursor]
        result = (result << 6) + UInt64(chr.value - 48)
        if i != 10 {
            cursor = cursor.predecessor()
        }
    }
    return result
}

/**
 * Compute the median given an array of numbers.
 */
func median(list:[Float]) -> Float {
    if list.count == 0 {
        return 0
    } else if list.count == 1 {
        return list[0]
    }
    let sortedList:[Float] = list.sorted {
        (Float first, Float second) -> Bool in
        return first < second
    }
    let middleIndex:Int = sortedList.count / 2
    if sortedList.count % 2 == 1 {
        return sortedList[middleIndex]
    } else {
        return (sortedList[middleIndex - 1] + sortedList[middleIndex]) / 2
    }
}

/**
 * Returns the lower 32 bits of a 64-bit unsigned number.
 */
func lower32Bits(num:UInt64) -> UInt {
    return UInt(num & 0xFFFFFFFF)
}

extension String {
    func replace(target: String, withString: String) -> String {
        return self.stringByReplacingOccurrencesOfString(target, withString: withString, options: NSStringCompareOptions.LiteralSearch, range: nil)
    }
}

func isUTF8Compatible(string:String) -> Bool {
    return NSString(string: string).lengthOfBytesUsingEncoding(NSUTF8StringEncoding) == string.utf16Count
}
