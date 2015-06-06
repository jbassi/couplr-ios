//
//  ChatLog.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 6/8/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class ChatMessage {
    
    /**
     * Initialize a ChatMessage from an incoming PubNub message.
     */
    convenience init(fromPNMessage: PNMessage) {
        self.init(rawText: fromPNMessage.message as! String)
    }
    
    /**
     * Initialize a ChatMessage from a Parse object.
     */
    convenience init(fromParseObject: AnyObject) {
        let rawText: String? = fromParseObject["text"] as? String
        if rawText == nil {
            self.init(text: "")
            didProperlyInitialize = false
        } else {
            self.init(rawText: fromParseObject["text"] as! String)
        }
    }
    
    private init(rawText: String) {
        let authorTimestampIndex: String.Index = find(rawText, kAuthorTimestampSeparator)!
        let timestampTextIndex: String.Index = find(rawText, kTimestampTextSeparator)!
        self.authorId = uint64FromAnyObject(rawText.substringToIndex(authorTimestampIndex), base64: false)
        let timeInSeconds: Int = rawText.substringWithRange(Range<String.Index>(start: authorTimestampIndex.successor(), end: timestampTextIndex)).toInt()!
        self.timestamp = NSDate(timeIntervalSince1970: Double(timeInSeconds))
        self.text = rawText.substringFromIndex(timestampTextIndex.successor())
    }
    
    /**
     * Initializes a ChatMessage directly from the given fields. If authorId is not given, attempts to use
     * SocialGraphController to obtain the root id. If the timestamp is not given, the current time is used.
     */
    init(text: String, authorId: UInt64 = 0, timestamp: NSDate? = nil) {
        self.authorId = authorId == 0 ? SocialGraphController.sharedInstance.rootId() : authorId
        self.timestamp = timestamp == nil ? NSDate() : timestamp!
        self.text = text
    }
    
    func isValid() -> Bool {
        return didProperlyInitialize && authorId != 0 || text != ""
    }
    
    /**
     * The message body is the text string representation of the necessary information in this message (i.e.
     * author id, a timestamp, and the message text).
     */
    func messageBody() -> String {
        return "\(authorId),\(Int(timestamp.timeIntervalSince1970)):\(text)"
    }
    
    func toString() -> String {
        return "[\(SocialGraphController.sharedInstance.nameFromId(authorId)) said: \"\(text)\" \(timestamp.ago())]"
    }
    
    var timestamp: NSDate
    var authorId: UInt64
    var text: String
    var didProperlyInitialize = true
}

class ChatLog : SequenceType {

    init(historicalMessageIds: [String]) {
        self.historicalMessageIds = historicalMessageIds
    }
    
    func latestMessage() -> ChatMessage? {
        if recentMessages.last == nil {
            return historicalMessages.first
        }
        return recentMessages.last
    }
    
    func earliestMessage() -> ChatMessage? {
        if historicalMessages.last == nil {
            return recentMessages.first
        }
        return historicalMessages.last
    }

    /**
     * Enforces a descending order of historical messages (from a previous session) by timestamp.
     * This method accepts a list of messages, since batch updates
     */
    func addEarlierMessages(messages: [ChatMessage]) {
        historicalMessages.extend(messages.sorted {
            $0.timestamp.compare($1.timestamp) == .OrderedDescending
        })
    }
    
    /**
     * Enforces an ascending order of recent messages (from the current session) by timestamp.
     */
    func addRecentMessage(message: ChatMessage) {
        recentMessages.append(message)
        if recentMessages.count > 1 && recentMessages[recentMessages.count - 2].timestamp.compare(message.timestamp) == .OrderedDescending {
            recentMessages.sort {
                $0.timestamp.compare($1.timestamp) == .OrderedAscending
            }
        }
    }
    
    /**
     * Fetches the ids of message objects starting from the first index given to the second index
     * given. fromIndex must
     */
    func historicalMessageIdsFrom(fromIndex: Int, toIndex: Int) -> [String] {
        return Array(historicalMessageIds[max(0, fromIndex)..<min(toIndex, historicalMessageIds.count)])
    }
    
    func generate() -> ChatMessageGenerator {
        return ChatMessageGenerator(historicalMessages: self.historicalMessages, recentMessages: self.recentMessages)
    }
    
    // Sorted in descending order.
    private var historicalMessages: [ChatMessage] = []
    // Sorted in ascending order.
    private var recentMessages: [ChatMessage] = []
    // Sorted in descending order.
    private var historicalMessageIds: [String]
    
    /**
     * Used to support time-ordered iteration over the messages in a ChatLog.
     */
    class ChatMessageGenerator : GeneratorType {
        
        init(historicalMessages: [ChatMessage], recentMessages: [ChatMessage]) {
            self.historicalMessages = historicalMessages
            self.recentMessages = recentMessages
            self.historicalMessagesIndex = historicalMessages.count - 1
            self.recentMessagesIndex = 0
        }
        
        func next() -> ChatMessage? {
            if historicalMessagesIndex >= 0 {
                historicalMessagesIndex--
                return historicalMessages[historicalMessagesIndex + 1]
            }
            if recentMessagesIndex < recentMessages.count {
                recentMessagesIndex++
                return recentMessages[recentMessagesIndex - 1]
            }
            return nil
        }
        
        var historicalMessagesIndex: Int
        var recentMessagesIndex: Int
        var historicalMessages: [ChatMessage]
        var recentMessages: [ChatMessage]
    }
}
