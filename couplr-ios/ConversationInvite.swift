//
//  ConversationInvite.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 6/8/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit


enum ConversationInviteState {
    case
    Invalid,        // Indicates that the state is inconsistent.
    Inbound,        // Indicates that the other user has sent an invite, but the root has not yet confirmed.
    Outbound,       // Indicates that that root has sent an invite that has not yet been confirmed.
    NewlyAccepted,  // Indicates that the invitation has been mutually accepted but not yet viewed by root.
    AlreadyAccepted // Indicates that the invitation has been mutually accepted and viewed by root.
}

class ConversationInvite {
    /**
     * Initializes a new conversation invite from a response object received
     * from a Parse request. Assumes that the root id is not equal to 0.
     */
    init(objectFromParse: AnyObject!) {
        let firstId: UInt64 = decodeBase64(objectFromParse["firstId"] as! String)
        let secondId: UInt64 = decodeBase64(objectFromParse["secondId"] as! String)
        meId = SocialGraphController.sharedInstance.rootId()
        if firstId == meId || secondId == meId {
            otherId = firstId == meId ? secondId : firstId
            otherName = firstId == meId ? objectFromParse["secondName"] as! String : objectFromParse["firstName"] as! String
            // Determine whether the match has been requested by me or the other user.
            let requestedByString: String = objectFromParse["requestedBy"] as! String
            let requestedById: UInt64 = decodeBase64(requestedByString)
            requestedByMe = requestedByString == "both" || requestedById == meId
            requestedByOther = requestedByString == "both" || requestedById == otherId
            // Determine whether I have seen the new pairing yet.
            let acknowledgedByString: String = objectFromParse["acknowledgedBy"] as! String
            acknowledgedByMe = acknowledgedByString == "both" || meId == decodeBase64(acknowledgedByString)
        } else {
            wasProperlyInitialized = false
        }
    }
    
    /**
     * Returns the current state of this conversation invite.
     */
    func state() -> ConversationInviteState {
        if !isValid() || (!requestedByMe && !requestedByOther) {
            return .Invalid
        }
        if requestedByMe && !requestedByOther {
            return .Outbound
        }
        if !requestedByMe && requestedByOther {
            return .Inbound
        }
        return acknowledgedByMe ? .AlreadyAccepted : .NewlyAccepted
    }
    
    /**
     * Returns whether the conversation invite was properly initialized.
     */
    func isValid() -> Bool {
        return wasProperlyInitialized && meId != 0 && otherId != 0
    }
    
    /**
     * Returns a human-readable string for debugging purposes.
     */
    func toString() -> String {
        let sgc = SocialGraphController.sharedInstance
        if !isValid() {
            return "[invalid invite: improperly initialized]"
        }
        let acknowledgmentStatus: String = acknowledgedByMe ? "acknowledged by me" : "not yet acknowledged by me"
        if requestedByMe && requestedByOther {
            return "[me: \(sgc.nameFromId(meId)), other: \(sgc.nameFromId(otherId)), requested by both, \(acknowledgmentStatus)]"
        } else if requestedByMe {
            return "[me: \(sgc.nameFromId(meId)), other: \(sgc.nameFromId(otherId)), requested by me, \(acknowledgmentStatus)]"
        } else if requestedByOther {
            return "[me: \(sgc.nameFromId(meId)), other: \(sgc.nameFromId(otherId)), requested by other, \(acknowledgmentStatus)]"
        }
        return "[invalid invite: neither has requested?]"
    }
    
    var meId: UInt64 = 0
    var otherId: UInt64 = 0
    var otherName: String = ""
    var requestedByMe: Bool = false
    var requestedByOther: Bool = false
    
    /**
     * Acknowledgment flags determine whether or not the root has seen
     * the conversation invite already. TL;DR Acknowledgement has to do
     * with notifying the root that the feeling is mutual.
     */
    var acknowledgedByMe: Bool = false
    
    /**
     * If init() hit an unexpected error, bails early and sets this flag
     * to false. Invalid ConversationInvites are ignored.
     */
    private var wasProperlyInitialized = true
}
