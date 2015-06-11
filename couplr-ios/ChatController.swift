//
//  ChatController.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 6/6/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import Parse

// MARK: Event handler interface

/**
 * An object that listens in on key ChatController events. This should really be a protocol instead of
 * a separate class, but I was not able to make it work with optional methods. Just extend this class and
 * override the methods you need to listen in on.
 */
class ChatEventHandler {
    /**
     * Invoked after first attempting to connect to PubNub, success or fail.
     */
    func handleConnectedToPubNub(success: Bool) { }
    
    /**
     * Invoked when a new conversation is formed. This is only called once, instead of every time we poll
     * for results.
     */
    func handleNewConversationInvites(invites: [ConversationInvite]) { }

    /**
     * Invoked when acknowledging a conversation request (i.e. when we want to remove the new conversation from
     * notifications).
     */
    func handleAcknowledgedRequestComplete(success: Bool, userId: UInt64) { }
    
    /**
     * Invoked when an invite polling operation completes, success or fail. Passes all valid ConversationInvites
     * to the handler.
     */
    func handlePollingComplete(success: Bool, invites: [ConversationInvite]) { }
    
    /**
     * Invoked when one or more conversations have been initialized. This means that the user can begin to post
     * messages to the conversation, and that the messages histories for these conversation has been fetched.
     */
    func handleLoadConversationHistoryComplete(success: Bool, conversations: [Conversation]) { }
    
    /**
     * Invoked when receiving a chatmessage. This includes messages sent by the root user.
     */
    func handleNewMessageReceived(message: ChatMessage, conversation: Conversation) { }
    
    /**
     * Invoked after fetching past messages.
     */
    func handleLoadPastMessagesComplete(success: Bool, messages: [ChatMessage], conversation: Conversation) { }
    
    /**
     * Invoked after unrequesting a conversation.
     */
    func handleUnrequestedConversation(success: Bool, withOtherId: UInt64) { }
}

// MARK: - Singleton ChatController class

class ChatController: NSObject {
    
    class var sharedInstance: ChatController {
        struct ChatControllerSingleton {
            static let instance = ChatController()
        }
        return ChatControllerSingleton.instance
    }
    
    // MARK: - Public controller API methods
    
    /**
     * Sets a handler that listens to chat server events.
     */
    func setHandler(handler: ChatEventHandler) {
        eventHandler = handler
    }
    
    /**
     * Requests a channel with the given user id.
     */
    func requestConversationWith(userId: UInt64) {
        log("Requesting pairing with \(socialGraphController.nameFromId(userId))...")
        let rootId: UInt64 = socialGraphController.rootId()
        if rootId == 0 || !socialGraphController.hasNameForUser(userId) {
            return log("Cannot request a channel before ids are known.", withFlag: "-", withIndent: 1)
        }
        dispatch_semaphore_wait(conversationInviteSemaphore, DISPATCH_TIME_FOREVER)
        let pair = MatchTuple(firstId: rootId, secondId: userId)
        var query = PFQuery(className: "Invite")
        query.whereKey("firstId", equalTo: encodeBase64(pair.firstId))
        query.whereKey("secondId", equalTo: encodeBase64(pair.secondId))
        query.findObjectsInBackgroundWithBlock { objects, error in
            dispatch_semaphore_signal(self.conversationInviteSemaphore)
            if error != nil {
                return log("Failed to request a channel with error: \(error!.description).", withFlag: "-", withIndent: 1)
            }
            // TODO Make sure creation of new ConversationInvites is atomic.
            if objects.count == 0 {
                // There is no existing invite from the root to the given user, so make a new one.
                let newInvite: PFObject = PFObject(className: "Invite")
                newInvite["firstId"] = encodeBase64(pair.firstId)
                newInvite["secondId"] = encodeBase64(pair.secondId)
                newInvite["firstName"] = self.socialGraphController.nameFromId(pair.firstId, maxStringLength: -1)
                newInvite["secondName"] = self.socialGraphController.nameFromId(pair.secondId, maxStringLength: -1)
                newInvite["acknowledgedBy"] = "none"
                newInvite["requestedBy"] = encodeBase64(rootId)
                newInvite.saveEventually()
                return log("Saved new chat request to Parse.", withIndent: 1)
            }
            let sortedObjects = Array(sorted(objects, {$0.objectId < $1.objectId}))
            // The other user already requested a channel with the root.
            let invite: ConversationInvite = ConversationInvite(objectFromParse: sortedObjects[0])
            if invite.isValid() {
                sortedObjects[0].setValue(invite.requestedByOther ? "both" : encodeBase64(rootId), forKey: "requestedBy")
                sortedObjects[0].saveEventually()
                log("Saved existing chat request to Parse.", withIndent: 1)
            } else {
                log("Failed to request a channel: could not initialize existing invite.", withFlag: "-", withIndent: 1)
            }
            // Remove all erroneous objects saved in Parse.
            for index: Int in 1..<sortedObjects.count {
                sortedObjects[index].deleteEventually()
            }
        }
    }
    
    /**
     * Undoes a request for a channel with the given user id.
     */
    func unrequestConversationWith(userId: UInt64) {
        log("Undoing pairing request with \(socialGraphController.nameFromId(userId))...")
        let rootId: UInt64 = socialGraphController.rootId()
        if rootId == 0 {
            return log("Cannot undo a channel request before the root id is known.", withFlag: "-", withIndent: 1)
        }
        dispatch_semaphore_wait(conversationInviteSemaphore, DISPATCH_TIME_FOREVER)
        let pair = MatchTuple(firstId: rootId, secondId: userId)
        var query = PFQuery(className: "Invite")
        query.whereKey("firstId", equalTo: encodeBase64(pair.firstId))
        query.whereKey("secondId", equalTo: encodeBase64(pair.secondId))
        query.getFirstObjectInBackgroundWithBlock { object, error in
            dispatch_semaphore_signal(self.conversationInviteSemaphore)
            // First, check for failure scenarios.
            if error != nil {
                self.eventHandler?.handleUnrequestedConversation(false, withOtherId: userId)
                return log("Failed to undo a channel request with error: \(error!.description).", withFlag: "-", withIndent: 1)
            }
            let invite: ConversationInvite = ConversationInvite(objectFromParse: object)
            if !invite.isValid() {
                self.eventHandler?.handleUnrequestedConversation(false, withOtherId: userId)
                return log("Failed to undo a channel request: could not parse existing invite.", withFlag: "-", withIndent: 1)
            }
            // Handle success scenarios.
            if invite.requestedByOther {
                object.setValue(encodeBase64(invite.otherId), forKey: "requestedBy")
                object.setValue("none", forKey: "acknowledgedBy")
                object.saveEventually()
                log("Removed vote from channel invite (object still exists).", withIndent: 1)
            } else {
                object.deleteEventually()
                log("Removed vote from channel invite (object deleted).", withIndent: 1)
            }
            // Unsubscribe from the channel.
            if let conversation: Conversation? = self.conversationsByOtherId[invite.otherId] {
                 PubNub.unsubscribeFrom([conversation!.channel])
            }
            // Delete the conversation.
            self.setConversationForId(invite.otherId, toConversation: nil)
            self.eventHandler?.handleUnrequestedConversation(true, withOtherId: userId)
        }
    }
    
    /**
     * Lets Parse know that the root user is aware of this new conversation.
     */
    func acknowledgeConversationWith(userId: UInt64) {
        log("Acknowledging chat with \(socialGraphController.nameFromId(userId))...")
        let rootId: UInt64 = socialGraphController.rootId()
        if rootId == 0 {
            return log("Cannot acknowledge channel request before the root id is known.", withFlag: "-", withIndent: 1)
        }
        dispatch_semaphore_wait(conversationInviteSemaphore, DISPATCH_TIME_FOREVER)
        let pair = MatchTuple(firstId: rootId, secondId: userId)
        var query = PFQuery(className: "Invite")
        query.whereKey("firstId", equalTo: encodeBase64(pair.firstId))
        query.whereKey("secondId", equalTo: encodeBase64(pair.secondId))
        query.getFirstObjectInBackgroundWithBlock { object, error in
            dispatch_semaphore_signal(self.conversationInviteSemaphore)
            // First, check for error conditions.
            if error != nil {
                self.eventHandler?.handleAcknowledgedRequestComplete(false, userId: userId)
                return log("Failed to acknowledge request with error: \(error!.description)", withFlag: "-")
            }
            // Update the acknowledgedBy column in Parse if necessary.
            let acknowledgedBy: String = object["acknowledgedBy"] as! String
            let acknowledgedId: UInt64 = decodeBase64(acknowledgedBy)
            if acknowledgedBy == "both" || acknowledgedId == rootId {
                self.eventHandler?.handleAcknowledgedRequestComplete(true, userId: userId)
                return log("Already acknowledged request. No action required.", withFlag: "?", withIndent: 1)
            }
            if acknowledgedBy == "none" {
                object.setValue(encodeBase64(rootId), forKey: "acknowledgedBy")
            } else {
                object.setValue("both", forKey: "acknowledgedBy")
            }
            log("Acknowledged conversation request.", withIndent: 1)
            object.saveEventually()
            self.eventHandler?.handleAcknowledgedRequestComplete(true, userId: userId)
        }
    }
    
    /**
     * Immediately attempts to update conversation invites and continues to poll for conversation
     * invites until stopped.
     */
    func startPollingForInvitations() {
        invitePollingTimer = NSTimer.scheduledTimerWithTimeInterval(kConversationInvitePollingPeriod, target: self, selector: Selector("fetchAndUpdateConversationInvites"), userInfo: nil, repeats: true)
        fetchAndUpdateConversationInvites()
    }
    
    /**
     * Immediately ends polling for invitations, invalidating any currently running update
     * calls.
     */
    func stopPollingForInvitations() {
        invitePollingTimer?.invalidate()
        invitePollingTimer = nil
    }
    
    /**
     * Queries Parse, updating the list of conversation invites. This is a read-only operation.
     */
    func fetchAndUpdateConversationInvites() {
        let rootId: UInt64 = socialGraphController.rootId()
        if rootId == 0 || !shouldPollForInvitations() {
            return log("Failed to update conversation invites: root user unknown or polling stopped early.", withFlag: "?")
        }
        dispatch_semaphore_wait(conversationInviteSemaphore, DISPATCH_TIME_FOREVER)
        let encodedRootId: String = encodeBase64(rootId)
        let predicate: NSPredicate = NSPredicate(format: "firstId = \"\(encodedRootId)\" OR secondId = \"\(encodedRootId)\"")
        var query = PFQuery(className: "Invite", predicate: predicate)
        query.findObjectsInBackgroundWithBlock { objects, error in
            dispatch_semaphore_signal(self.conversationInviteSemaphore)
            if error != nil {
                self.eventHandler?.handlePollingComplete(false, invites: [])
                return log("An error occurred in conversation invite polling: \(error!.description)", withFlag: "-")
            }
            if !self.shouldPollForInvitations() {
                self.eventHandler?.handlePollingComplete(false, invites: [])
                return log("Invitation polling stopped: returning early.", withFlag: "?")
            }
            var invites: [ConversationInvite] = []
            for object in objects {
                let invite: ConversationInvite = ConversationInvite(objectFromParse: object)
                if invite.isValid() {
                    invites.append(invite)
                    self.socialGraphController.addNameForUserId(invite.otherId, name: invite.otherName)
                } else {
                    log("Ignoring invalid invitation: \(invite.toString())", withFlag: "-")
                }
            }
            log("Invitations polled: \(invites.count) total invitation(s).")
            for invite: ConversationInvite in invites {
                log(invite.toString(), withIndent: 1)
            }
            self.eventHandler?.handlePollingComplete(true, invites: invites)
            var channelsPendingSubscription: [PNChannel] = []
            for invite: ConversationInvite in invites {
                switch invite.state() {
                case .Inbound:
                    self.inboundInvites[invite.otherId] = invite
                case .Outbound:
                    self.outboundInvites[invite.otherId] = invite
                case .NewlyAccepted, .AlreadyAccepted:
                    if self.conversationsByOtherId[invite.otherId] == nil {
                        let conversation = Conversation(invite: invite)
                        self.setConversationForId(invite.otherId, toConversation: conversation)
                        channelsPendingSubscription.append(conversation.channel)
                    }
                default:
                    break
                }
            }
            // Subscribe immediately upon receiving knowledge of the accepted channels.
            if !channelsPendingSubscription.isEmpty {
                PubNub.subscribeOn(channelsPendingSubscription)
                log("Initializing and subscribing to \(channelsPendingSubscription.count) channel(s)...")
            }
            let newUnacknowledgedInvites: [ConversationInvite] = Array(self.conversationsByOtherId.values.filter({
                return !$0.invite.acknowledgedByMe && !self.knownInviteAcceptedUserIds.contains($0.invite.otherId)
            }).map {$0.invite})
            self.eventHandler?.handleNewConversationInvites(newUnacknowledgedInvites)
            for invite: ConversationInvite in newUnacknowledgedInvites {
                self.knownInviteAcceptedUserIds.insert(invite.otherId)
            }
        }
    }
    
    /**
     * Sends a message to the given user id. Exits early if the conversation is not yet ready or there
     * is no existing chatroom with the user id.
     */
    func sendMessage(message: String, toUserId: UInt64) {
        let rootId: UInt64 = socialGraphController.rootId()
        // Handle error scenarios first.
        if message == "" || rootId == 0 {
            return log("Failed to send message to \(socialGraphController.nameFromId(toUserId)): invalid text or root id.", withFlag: "-")
        }
        let conversation: Conversation? = self.conversationsByOtherId[toUserId]
        if conversation == nil || !conversation!.isReady() {
            return log("Failed to send message to \(socialGraphController.nameFromId(toUserId)): conversation missing or not ready.", withFlag: "+")
        }
        log("Attempting to save a message to \(conversation!.invite.otherName) in Parse...", withFlag: "!")
        // Save a new chatmessage and then append its object id to the message history.
        let chatMessage: ChatMessage = ChatMessage(text: message, authorId: rootId)
        conversation!.unconfirmedMessages.append(chatMessage)
        let messageObject: PFObject = PFObject(className: "Message")
        messageObject["text"] = chatMessage.messageBody()
        messageObject.saveInBackgroundWithBlock { success, error in
            if error != nil || !success {
                return log("Failed to create new Message object in Parse with error \(error?.description)", withFlag: "-")
            }
            let messageId: String = messageObject.objectId
            let query: PFQuery = PFQuery(className: "MessageHistory")
            query.whereKey("channel", equalTo: conversation!.channel.name)
            query.findObjectsInBackgroundWithBlock { objects, error in
                if error != nil {
                    log("Failed to append message to request history with error \(error!.description)", withFlag: "-")
                    return messageObject.deleteEventually()
                }
                var historyObject: PFObject? = nil
                if objects.count == 0 {
                    // No history object exists, so save a new history object to Parse.
                    historyObject = PFObject(className: "MessageHistory")
                    historyObject!["channel"] = conversation!.channel.name
                    historyObject!["messageIds"] = [messageId]
                } else {
                    // Just in case redundant chat histories exist, take the one with lesser objectId.
                    historyObject = objects.sorted({ $0.objectId < $1.objectId }).first! as? PFObject
                    historyObject!.addObject(messageId, forKey: "messageIds")
                }
                historyObject!.saveInBackgroundWithBlock { success, error in
                    if error != nil || !success {
                        log("Failed to append message id to history with error \(error?.description)", withFlag: "-")
                        return messageObject.deleteEventually()
                    }
                    // Delete the ChatMessage from unconfirmed messages and add it to recent messages.
                    conversation!.confirmMessageSavedToParse(chatMessage)
                    PubNub.sendMessage(chatMessage.messageBody(), toChannel: conversation!.channel)
                    log("Successfully saved message id \"\(messageId)\" to Parse.", withIndent: 1)
                }
            }
        }
    }
    
    /**
     * Fetches up to a given number of messages from the conversation with the given user id. The messages
     * are fetched in reverse chronological order, starting from the most recent message sent before the
     * current session began.
     */
    func fetchPastMessagesForConversationWith(otherId: UInt64, maxNumMessages: Int = kMaxNumPastMessagesPerPage) {
        let conversation: Conversation? = conversationsByOtherId[otherId]
        if conversation == nil {
            return log("Failed to fetch past messages: no such conversation with other id \(otherId)", withFlag: "-")
        }
        conversation!.fetchPastMessages(maxNumMessages: maxNumMessages, onComplete: { success, messages, conversation in
            self.eventHandler?.handleLoadPastMessagesComplete(success, messages: messages, conversation: conversation)
        })
    }
    
    /**
     * Returns a list of conversations sorted by update time. The first entry in the result is the
     * conversation that has most recently been updated.
     */
    func conversationsSortedByUpdateTime() -> [Conversation] {
        return Array(conversationsByOtherId.values).sorted { before, after in
            if before.chatLog == nil {
                return false
            }
            if after.chatLog == nil {
                return true
            }
            return before.chatLog!.updatedAt.compare(after.chatLog!.updatedAt) == .OrderedDescending
        }
    }
    
    // MARK: - Private subroutines and fields
    
    private func shouldPollForInvitations() -> Bool {
        return invitePollingTimer != nil
    }
    
    private func setConversationForId(otherId: UInt64, toConversation: Conversation?) {
        self.conversationsByOtherId[otherId] = toConversation
        if let channelName: String? = ChatController.channelNameForOtherId(otherId) {
            self.conversationsByChannelName[channelName!] = toConversation
        }
    }
    
    static func channelNameForOtherId(userId: UInt64) -> String? {
        let rootId: UInt64 = SocialGraphController.sharedInstance.rootId()
        if rootId == 0 {
            return nil
        }
        let pair: MatchTuple = MatchTuple(firstId: rootId, secondId: userId)
        return "couplr_\(pair.firstId)_\(pair.secondId)"
    }
    
    // Invitation state variables.
    private var invitePollingTimer: NSTimer? = nil
    private var inboundInvites: [UInt64: ConversationInvite] = [UInt64: ConversationInvite]()
    private var outboundInvites: [UInt64: ConversationInvite] = [UInt64: ConversationInvite]()
    private var knownInviteAcceptedUserIds: Set<UInt64> = Set<UInt64>()
    private var eventHandler: ChatEventHandler? = nil
    private var conversationInviteSemaphore = dispatch_semaphore_create(1)
    
    // Conversation state variables.
    private var conversationsByOtherId: [UInt64: Conversation] = [UInt64: Conversation]()
    private var conversationsByChannelName: [String: Conversation] = [String: Conversation]()
    
    // For convenience only.
    private let socialGraphController = SocialGraphController.sharedInstance
    private let matchGraphController = MatchGraphController.sharedInstance
}

// MARK: - PubNub Delegation

extension ChatController: PNDelegate {
    func pubnubClient(client: PubNub!, didConnectToOrigin origin: String!) {
        self.eventHandler?.handleConnectedToPubNub(true)
    }
    
    func pubnubClient(client: PubNub!, connectionDidFailWithError error: PNError!) {
        // TODO Handle connection failure.
        self.eventHandler?.handleConnectedToPubNub(false)
    }
    
    func pubnubClient(client: PubNub!, didReceiveMessage message: PNMessage!) {
        if let conversation: Conversation? = conversationsByChannelName[message.channel.name] {
            let chatMessage: ChatMessage = ChatMessage(fromPNMessage: message)
            conversation!.chatLog?.addRecentMessage(chatMessage)
            self.eventHandler?.handleNewMessageReceived(chatMessage, conversation: conversation!)
        }
    }
    
    /**
     * Mark the appropriate conversations as readied.
     */
    func pubnubClient(client: PubNub!, didSubscribeOnChannels channels: [AnyObject]!) {
        var otherIdsByChannelName: [String: UInt64] = [String: UInt64]()
        for (otherId: UInt64, conversation: Conversation) in conversationsByOtherId {
            otherIdsByChannelName[conversation.channel.name] = otherId
        }
        var numReadyChannels: Int = 0
        var readiedChatsWithIds: [UInt64] = []
        for channelObject in channels {
            if let channel: PNChannel? = channelObject as? PNChannel {
                if let otherId: UInt64? = otherIdsByChannelName[channel!.name] {
                    conversationsByOtherId[otherId!]!.hasLoadedChannel = true
                    numReadyChannels++
                    readiedChatsWithIds.append(otherId!)
                }
            }
        }
        log("Subscribed to \(numReadyChannels) channel(s).")
        // After subscribing to the conversation channels for each of the given user ids, fetch the
        // message history for each of the channels.
        let query: PFQuery = PFQuery(className: "MessageHistory")
        query.whereKey("channel", containedIn: Array(conversationsByChannelName.keys))
        query.findObjectsInBackgroundWithBlock { historyObjects, error in
            if error != nil {
                self.eventHandler?.handleLoadConversationHistoryComplete(false, conversations: [])
                return log("Failed to fetch message history for channel names.", withFlag: "-")
            }
            var conversationsInitialized: [Conversation] = []
            for i in 0..<historyObjects.count {
                let historyObject: AnyObject = historyObjects[i]
                var messageIds: [String] = []
                if let messageIdsObject: AnyObject? = historyObject["messageIds"] {
                    for index in 0..<messageIdsObject!.count {
                        messageIds.append(messageIdsObject![index] as! String)
                    }
                    let channelName: String = historyObject["channel"] as! String
                    if let conversation: Conversation? = self.conversationsByChannelName[channelName] {
                        log("Loaded conversation with \(conversation!.invite.otherName): found \(messageIds.count) message(s)", withIndent: 1)
                        conversation!.chatLog = ChatLog(historicalMessageIds: messageIds.reverse(), updatedAt: historyObject.updatedAt)
                        conversationsInitialized.append(conversation!)
                    }
                }
            }
            for (channelName: String, conversation: Conversation) in self.conversationsByChannelName {
                if conversation.hasLoadedChannel && conversation.chatLog == nil {
                    // The conversation does not have a history saved in Parse, but has a channel.
                    let newHistoryObject: PFObject = PFObject(className: "MessageHistory")
                    newHistoryObject["channel"] = channelName
                    newHistoryObject["messageIds"] = []
                    newHistoryObject.saveEventually()
                    conversation.chatLog = ChatLog(historicalMessageIds: [], updatedAt: NSDate())
                    conversationsInitialized.append(conversation)
                }
            }
            self.eventHandler?.handleLoadConversationHistoryComplete(true, conversations: conversationsInitialized)
        }
    }
}
