//
//  CouplrLoginErrorHandler.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 9/13/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class CouplrLoginErrorHandler: NSObject {
    class func handleError(error: NSError?) {
        if(error != nil) {
            var alertMessage: String = ""
            var alertTitle: String = ""
            
            if(FBErrorUtility.shouldNotifyUserForError(error)) {
                alertTitle = "Something went wrong."
                alertTitle = FBErrorUtility.userMessageForError(error)
            } else {
                // TODO: Handle other error cases accordingly
                switch FBErrorUtility.errorCategoryForError(error) {
                case FBErrorCategory.AuthenticationReopenSession:
                    alertTitle = "Session Error"
                    alertMessage = "Your current session is no longer valid. Please log in again."
                case FBErrorCategory.UserCancelled:
                    alertTitle = "Session Error"
                    alertMessage = "Please log in with Facebook to use Couplr."
                default:
                    alertTitle = "Unknown Error"
                    alertMessage = "Error: Please try again later."
                }
            }
            
            let alertView = UIAlertView(title: alertTitle, message: alertMessage, delegate: nil, cancelButtonTitle: "OK")
            alertView.show()
        }
    }
}
