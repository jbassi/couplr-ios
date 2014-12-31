//
//  CouplerFBRequestHandler.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/30/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

protocol CouplrFBRequestHandlerDelegate: class {
    func couplrFBRequestHandlerWillRecieveInvitableFriends()
    func couplrFBRequestHandlerDidRecieveInvitableFriends(array: NSArray)
}

class CouplrFBRequestHandler {
    
    weak var delegate: CouplrFBRequestHandlerDelegate?
    
    init() {
        delegate = nil
    }
    
    func requestInvitableFriends() {
        self.delegate?.couplrFBRequestHandlerWillRecieveInvitableFriends()
        
        FBRequestConnection.startWithGraphPath("me/invitable_friends?fields=picture.height(200).width(200)", completionHandler: {(connection: FBRequestConnection!, result: AnyObject!, error: NSError!) in
            let invitableFriendDictionary = result as NSDictionary
            let friendData = invitableFriendDictionary.objectForKey("data") as NSArray
            self.delegate?.couplrFBRequestHandlerDidRecieveInvitableFriends(friendData)
        })
    }
    
}