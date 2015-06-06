//
//  UserAnalytics.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 4/12/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import Parse

public class UserSessionTracker {
    public init() {
        self.appStartTime = currentTimeInSeconds()
        self.session = []
        self.logMessages = []
        self.lastKnownRoot = 0
    }
    
    class var sharedInstance: UserSessionTracker {
        struct UserSessionTrackerSingleton {
            static let instance = UserSessionTracker()
        }
        return UserSessionTrackerSingleton.instance
    }
    
    public func notify(action: String) {
        let timeElapsed: Double = currentTimeInSeconds() - self.appStartTime
        if session.count < 99 {
            session.append(action, timeElapsed)
        } else if session.count == 99 {
            session.append("...", timeElapsed)
        }
    }
    
    public func appendLog(message: String) {
        self.logMessages.append(message)
        if self.logMessages.count > kMaxNumDebugLogLines {
            self.logMessages.removeAtIndex(0)
        }
    }
    
    public func flushUserSession() {
        tryToUpdateLastKnownRoot()
        let encodedRoot: String = encodeBase64(lastKnownRoot)
        if encodedRoot == "2I8<O^K4T00" || encodedRoot == "860JAQC@T00" {
            return // HACK This is to stop our usage sessions from flooding our analytics data.
        }
        if lastKnownRoot == 0 {
            return log("Should not log user session for unknown root user.", withFlag: "-")
        }
        var userSession: PFObject = PFObject(className: "UserSession")
        userSession["userId"] = encodedRoot
        userSession["startTime"] = round(appStartTime)
        userSession["data"] = "[" + ", ".join(session.map { (action: String, time: Double) -> String in
            return "{\"action\": \"\(action)\", \"time\": \(round(100 * time) / 100)}"
        }) + "]"
        userSession.saveEventually()
        session.removeAll()
    }
    
    public func tryToUpdateLastKnownRoot() {
        let currentRootId: UInt64 = SocialGraphController.sharedInstance.rootId()
        if currentRootId != 0 {
            lastKnownRoot = currentRootId
        }
    }
    
    public func flushLog() {
        tryToUpdateLastKnownRoot()
        if logMessages.count == 0 {
            return
        }
        var userLog: PFObject = PFObject(className: "UserLog")
        userLog["output"] = "\n".join(logMessages)
        userLog["rootId"] = encodeBase64(lastKnownRoot)
        userLog["startTime"] = round(appStartTime)
        userLog.saveEventually()
        logMessages.removeAll()
    }
    
    var appStartTime: Double
    var session: [(String, Double)]
    var logMessages: [String]
    var lastKnownRoot: UInt64
}
