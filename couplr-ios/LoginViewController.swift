//
//  LoginViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 9/13/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, FBLoginViewDelegate {
    
    @IBOutlet var loginView: FBLoginView!
    @IBOutlet var continueButton: UIButton!
    
    var viewDidAppear: Bool = false
    var viewIsVisible: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        continueButton.hidden = true
        loginView.delegate = self
        loginView.readPermissions = ["read_stream", "public_profile", "email", "user_friends", "user_birthday", "friends_birthday"]
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        var settings: CouplrSettingsManager = CouplrSettingsManager.sharedInstance
        if (viewDidAppear) {
            viewIsVisible = true;
            settings.shouldSkipLogin = false;
        } else {
            FBSession.openActiveSessionWithAllowLoginUI(false)
            var activeSession: FBSession = FBSession.activeSession()
            
            if(settings.shouldSkipLogin || activeSession.isOpen) {
                self.performSegueWithIdentifier("ShowTabBarViewController", sender: nil)
            } else {
                viewIsVisible = true
            }
            viewDidAppear = true
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        CouplrSettingsManager.sharedInstance.shouldSkipLogin = false
        viewIsVisible = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - IBActions
    @IBAction func showLogin(segue: UIStoryboardSegue) {
        // Left intentionally blank to create an unwind swgue to this controller
    }
    
    // MARK: - Facebook Delegate Methods
    func loginViewShowingLoggedInUser(loginView : FBLoginView!) {
        if (viewIsVisible) {
            self.performSegueWithIdentifier("ShowTabBarViewController", sender: nil)
        }
    }
    
    func loginViewShowingLoggedOutUser(loginView: FBLoginView!) {
        continueButton.hidden = true
    }
    
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser) {
        var buttonTitle: String = "Continue As \(user.name)..."
        continueButton.setTitle(buttonTitle, forState: UIControlState.Normal)
        continueButton.hidden = false
    }
    
    func loginView(loginView : FBLoginView!, handleError:NSError) {
        CouplrLoginErrorHandler.handleError(handleError)
    }
}
