//
//  LoginViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 9/13/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit
import CoreData

class LoginViewController: UIViewController {

    let loginView: FBLoginView = FBLoginView()
    let continueButton: UIButton = UIButton()

    var viewDidAppear: Bool = false
    var viewIsVisible: Bool = false

    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginView.delegate = self
        loginView.readPermissions = ["user_friends", "user_status", "user_posts", "user_photos"]
        let loginViewX:CGFloat = (view.bounds.width / 2) - (loginView.bounds.width / 2)
        let loginViewY:CGFloat = (view.bounds.height / 2) - (loginView.bounds.height / 2)
        loginView.frame.origin = CGPointMake(loginViewX, loginViewY)
        
        continueButton.hidden = true
        let continueButtonX:CGFloat = (view.bounds.width / 2) - (loginView.frame.width / 2)
        let continueButtonY:CGFloat = (view.bounds.height / 2) + (loginView.frame.height / 2)
        continueButton.frame = CGRectMake(continueButtonX, continueButtonY, loginView.frame.width, loginView.frame.height)
        continueButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        continueButton.addTarget(self, action: "continueButtonPressed:", forControlEvents: .TouchUpInside)
        
        view.backgroundColor = UIColor.whiteColor()
        view.addSubview(loginView)
        view.addSubview(continueButton)
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
                loadAppViewsAndPresentNavigationController()
            } else {
                viewIsVisible = true
            }
            viewDidAppear = true
        }
    }

    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)

        CouplrSettingsManager.sharedInstance.shouldSkipLogin = true
        viewIsVisible = false
    }
    
    func loadAppViewsAndPresentNavigationController() {
        let pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        let couplrNavigationController: CouplrNavigationController = CouplrNavigationController(rootViewController: pageViewController)

        let profileViewController = ProfileViewController()
        let matchViewController = MatchViewController()
        let newsfeedViewController = NewsfeedViewController()

        couplrNavigationController.viewControllerArray.append(profileViewController)
        couplrNavigationController.viewControllerArray.append(matchViewController)
        couplrNavigationController.viewControllerArray.append(newsfeedViewController)

        CouplrControllers.sharedInstance.navigationController = couplrNavigationController
        CouplrControllers.sharedInstance.profileViewController = profileViewController
        CouplrControllers.sharedInstance.matchViewController = matchViewController
        CouplrControllers.sharedInstance.newsfeedViewController = newsfeedViewController
        
        couplrNavigationController.modalTransitionStyle = .FlipHorizontal
        presentViewController(couplrNavigationController, animated: true, completion: nil)
        
        socialGraphController.reset()
        matchGraphController.reset()
    }
    
    func continueButtonPressed(sender: UIButton) {
        loadAppViewsAndPresentNavigationController()
    }

}

// MARK: - Facebook Delegate Methods

extension LoginViewController: FBLoginViewDelegate {
    
    func loginViewShowingLoggedInUser(loginView : FBLoginView!) {
        if (viewIsVisible) {
            loadAppViewsAndPresentNavigationController()
        }
    }
    
    func loginViewShowingLoggedOutUser(loginView: FBLoginView!) {
        continueButton.hidden = true
    }
    
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser) {
        var buttonTitle: String = "Continue As \(user.name)..."
        continueButton.setTitle(buttonTitle, forState: UIControlState.Normal)
        continueButton.sizeToFit()
        continueButton.hidden = false
    }
    
    func loginView(loginView : FBLoginView!, handleError:NSError) {
        CouplrLoginErrorHandler.handleError(handleError)
    }
    
}
