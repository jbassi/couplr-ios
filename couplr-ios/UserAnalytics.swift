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
    
    public func flushUserSession() {
        let encodedRoot: String = encodeBase64(SocialGraphController.sharedInstance.rootId())
        if encodedRoot == "2I8<O^K4T00" || encodedRoot == "860JAQC@T00" {
            return // HACK This is to stop our usage sessions from flooding our analytics data.
        }
        var userSession: PFObject = PFObject(className: "UserSession")
        userSession["userId"] = encodedRoot
        userSession["startTime"] = round(self.appStartTime)
        userSession["data"] = "[" + ", ".join(session.map { (action: String, time: Double) -> String in
            return "{\"action\": \"\(action)\", \"time\": \(round(100 * time) / 100)}"
        }) + "]"
        userSession.save()
        session = []
    }
    
    var appStartTime: Double
    var session: [(String, Double)]
}
