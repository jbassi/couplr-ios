//
//  Conversation.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 6/11/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import Parse

/**
 * The first id is assumed to be the root user.
 */
class Conversation {
    init(invite: ConversationInvite) {
        self.invite = invite
        self.channel = PNChannel.channelWithName(ChatController.channelNameForOtherId(invite.otherId)!, shouldObservePresence: true) as! PNChannel!
    }
    
    func isReady() -> Bool {
        return hasLoadedChannel && chatLog != nil
    }
    
    func fetchPastMessages(maxNumMessages: Int = kMaxNumPastMessagesPerPage, onComplete: ((success: Bool, messages: [ChatMessage], conversation: Conversation) -> Void)? = nil) {
        if !isReady() {
            onComplete?(success: false, messages: [], conversation: self)
            return log("Cannot invoke Conversation::fetchPastMessages before conversation is ready.", withFlag: "-")
        }
        let nextMessagesIndex: Int = currentMessageIndex + maxNumMessages
        let messageIds: [String] = chatLog!.historicalMessageIdsFrom(currentMessageIndex, toIndex: nextMessagesIndex)
        if messageIds.count == 0 {
            noMoreMessagesToFetch = true
        }
        if noMoreMessagesToFetch {
            onComplete?(success: true, messages: [], conversation: self)
            return log("No more messages to fetch.")
        }
        dispatch_semaphore_wait(chatHistorySemaphore, DISPATCH_TIME_FOREVER)
        let query: PFQuery = PFQuery(className: "Message")
        query.whereKey("objectId", containedIn: messageIds)
        query.findObjectsInBackgroundWithBlock { messageObjects, error in
            dispatch_semaphore_signal(self.chatHistorySemaphore)
            if error != nil {
                onComplete?(success: false, messages: [], conversation: self)
                return log("Failed to fetch chat history with error: \(error!.description).", withFlag: "-")
            }
            let validMessages: [ChatMessage] = messageObjects.map({ ChatMessage(fromParseObject: $0) }).filter { $0.isValid() }
            self.chatLog!.addEarlierMessages(validMessages)
            log("Fetched \(validMessages.count) message(s). Moved message index to \(nextMessagesIndex).")
            self.currentMessageIndex = nextMessagesIndex
            onComplete?(success: true, messages: validMessages, conversation: self)
        }
    }
    
    func confirmMessageSavedToParse(message: ChatMessage) {
        if chatLog == nil {
            return;
        }
        var unconfirmedMessageIndex: Int = -1
        for (index: Int, chatMessage: ChatMessage) in enumerate(unconfirmedMessages) {
            if message === chatMessage {
                unconfirmedMessageIndex = index
            }
        }
        if unconfirmedMessageIndex != -1 {
            unconfirmedMessages.removeAtIndex(unconfirmedMessageIndex)
        }
    }
    
    func toString() -> String {
        var result = ""
        let numMessages: Int = chatLog == nil ? 0 : chatLog!.numTotalMessages()
        let numFetchedMessages: Int = chatLog == nil ? 0 : chatLog!.numFetchedMessages()
        result += "- \(invite.otherName) (\(numFetchedMessages)/\(numMessages) messages fetched)\n"
        if chatLog == nil {
            result += "    - Conversation chat not yet loaded.\n"
        } else if numFetchedMessages == 0 {
            result += "    - No fetched messages.\n"
        } else {
            for message: ChatMessage in chatLog! {
                result += "    - \(message.toString())\n"
            }
        }
        return result
    }
    
    var currentMessageIndex: Int = 0
    var invite: ConversationInvite
    var channel: PNChannel
    var chatLog: ChatLog? = nil
    // Unconfirmed messages are messages that have not yet been saved to Parse.
    var unconfirmedMessages: [ChatMessage] = []
    var hasLoadedChannel: Bool = false
    var noMoreMessagesToFetch: Bool = false
    
    private var chatHistorySemaphore = dispatch_semaphore_create(1)
}
