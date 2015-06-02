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
    let pageControl: UIPageControl = UIPageControl()
    let attributionLabel: UILabel = UILabel()
    var viewControllerArray = Array<UIViewController>()
    var pageViewController: UIPageViewController!

    var viewDidAppear: Bool = false
    var viewIsVisible: Bool = false

    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginView.hidden = true
        continueButton.hidden = true
        pageControl.hidden = true
        
        let viewWidth: CGFloat = view.bounds.width
        let viewHeight: CGFloat = view.bounds.height
        
        loginView.delegate = self
        loginView.readPermissions = ["user_friends", "user_status", "user_posts", "user_photos"]
        let loginViewX: CGFloat = (view.bounds.width / 2) - (loginView.bounds.width / 2)
        let loginViewY: CGFloat = view.bounds.height - 40 - (loginView.bounds.height / 2)
        loginView.frame.origin = CGPointMake(loginViewX, loginViewY)
        
        let continueButtonY: CGFloat = (view.bounds.height / 2) + (loginView.frame.height / 2)
        continueButton.frame = CGRectMake(0, continueButtonY, view.frame.size.width, 50)
        continueButton.titleLabel?.adjustsFontSizeToFitWidth = true
        continueButton.titleLabel?.textAlignment = .Center
        continueButton.setTitleColor(view.tintColor, forState: .Normal)
        continueButton.addTarget(self, action: "continueButtonPressed:", forControlEvents: .TouchUpInside)
        
        let matchTutorialPage = TutorialPageViewController()
        matchTutorialPage.pageIndex = 0
        matchTutorialPage.screenFileName = "tutorial-screen-match"
        matchTutorialPage.descriptionText = kTutorialMatchDescription
        let profileTutorialPage = TutorialPageViewController()
        profileTutorialPage.pageIndex = 1
        profileTutorialPage.screenFileName = "tutorial-screen-profile"
        profileTutorialPage.descriptionText = kTutorialProfileDescription
        let newsfeedTutorialPage = TutorialPageViewController()
        newsfeedTutorialPage.pageIndex = 2
        newsfeedTutorialPage.screenFileName = "tutorial-screen-newsfeed"
        newsfeedTutorialPage.descriptionText = kTutorialNewsfeedDescription
        
        viewControllerArray.append(matchTutorialPage)
        viewControllerArray.append(profileTutorialPage)
        viewControllerArray.append(newsfeedTutorialPage)
        
        let pageControlX: CGFloat = (view.bounds.width / 2) - (pageControl.bounds.width / 2)
        let pageControlY: CGFloat = loginViewY - 20
        pageControl.frame.origin = CGPointMake(pageControlX, pageControlY)
        pageControl.numberOfPages = viewControllerArray.count
        pageControl.currentPage = 0
        pageControl.pageIndicatorTintColor = UIColor.grayColor()
        pageControl.currentPageIndicatorTintColor = UIColor.blackColor()
        
        pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.setViewControllers([viewControllerArray[0]], direction: .Forward, animated: false, completion: nil)
        pageViewController.view.frame = CGRectMake(0, kStatusBarHeight+20, view.bounds.width, view.bounds.height-kStatusBarHeight-pageControl.frame.size.height-loginView.frame.size.height-70)
        pageViewController.view.hidden = true
        
        attributionLabel.text = "Icons made by Freepik from www.flaticon.com. Flaticon is licensed by Creative Commons 3.0"
        attributionLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        attributionLabel.numberOfLines = 0
        attributionLabel.textAlignment = NSTextAlignment.Center
        attributionLabel.font = UIFont(name: "HelveticaNeue-Light", size: 10)
        attributionLabel.frame = CGRectMake(0, viewHeight - 36, viewWidth, 36).withMargin(horizontal: 10, vertical: 3)
        attributionLabel.hidden = true
        
        view.backgroundColor = UIColor.whiteColor()
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        view.addSubview(pageControl)
        view.addSubview(loginView)
        view.addSubview(continueButton)
        view.addSubview(attributionLabel)
        
        view.bringSubviewToFront(pageControl)
        pageViewController.didMoveToParentViewController(self)
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
                loadAppViewsAndPresentNavigationController(false)
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
    
    func loadAppViewsAndPresentNavigationController(animated: Bool) {
        let pageViewController = UIPageViewController(transitionStyle: .Scroll, navigationOrientation: .Horizontal, options: nil)
        let couplrNavigationController: CouplrNavigationController = CouplrNavigationController(rootViewController: pageViewController)

        let profileViewController = ProfileViewController()
        let newsfeedViewController = NewsfeedViewController()
        let matchViewController = MatchViewController()
        let historyViewController = HistoryViewController()

        couplrNavigationController.viewControllerArray.append(profileViewController)
        couplrNavigationController.viewControllerArray.append(newsfeedViewController)
        couplrNavigationController.viewControllerArray.append(matchViewController)
        couplrNavigationController.viewControllerArray.append(historyViewController)

        CouplrViewCoordinator.sharedInstance.navigationController = couplrNavigationController
        CouplrViewCoordinator.sharedInstance.profileViewController = profileViewController
        CouplrViewCoordinator.sharedInstance.newsfeedViewController = newsfeedViewController
        CouplrViewCoordinator.sharedInstance.matchViewController = matchViewController
        CouplrViewCoordinator.sharedInstance.historyViewController = historyViewController
        
        couplrNavigationController.modalTransitionStyle = .CrossDissolve
        presentViewController(couplrNavigationController, animated: true, completion: nil)
        if CouplrViewCoordinator.sharedInstance.tryToCreateAndShowLoadingView() {
            socialGraphController.reset()
            matchGraphController.reset()
        }
    }
    
    func continueButtonPressed(sender: UIButton) {
        loadAppViewsAndPresentNavigationController(true)
    }
    
    func hideTutorial() {
        loginView.hidden = false
        pageViewController.view!.hidden = true
        pageControl.hidden = true
        continueButton.hidden = false
        attributionLabel.hidden = false
        
        pageViewController.removeFromParentViewController()
        pageViewController.view.removeFromSuperview()
        pageControl.removeFromSuperview()
        let loginViewY: CGFloat = (view.bounds.height / 2) - (loginView.bounds.height / 2)
        loginView.frame.origin.y = loginViewY
    }
    
    func showTutorial() {
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        view.addSubview(pageControl)
        
        loginView.hidden = false
        continueButton.hidden = true
        pageViewController.view!.hidden = false
        pageControl.hidden = false
        attributionLabel.hidden = true
        
        let loginViewY: CGFloat = view.bounds.height - 40 - (loginView.bounds.height / 2)
        loginView.frame.origin.y = loginViewY
        
        view.bringSubviewToFront(pageControl)
        
        pageViewController.view.alpha = 0.0
        pageControl.alpha = 0.0
        loginView.alpha = 0.0
        
        UIView.animateWithDuration(0.25, animations: {
            self.pageViewController.view.alpha = 1.0
            self.pageControl.alpha = 1.0
            self.loginView.alpha = 1.0
        })
    }

}

// MARK: - Facebook Delegate Methods

extension LoginViewController: FBLoginViewDelegate {
    
    func loginViewShowingLoggedInUser(loginView : FBLoginView!) {
        if (viewIsVisible) {
            loadAppViewsAndPresentNavigationController(false)
        }
    }
    
    func loginViewShowingLoggedOutUser(loginView: FBLoginView!) {
        showTutorial()
    }
    
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser) {
        var buttonTitle: String = "Continue As \(user.name)..."
        continueButton.setTitle(buttonTitle, forState: UIControlState.Normal)
        hideTutorial()
    }
    
    func loginView(loginView : FBLoginView!, handleError: NSError) {
        CouplrLoginErrorHandler.handleError(handleError)
    }
    
}

extension LoginViewController: UIPageViewControllerDataSource, UIPageViewControllerDelegate {
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        let tutorialPage = viewController as! TutorialPageViewController
        var index = tutorialPage.pageIndex
        
        if (--index <= -1) {
            return nil
        }
        
        return viewControllerArray[index]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        let tutorialPage = viewController as! TutorialPageViewController
        var index = tutorialPage.pageIndex
        
        if (++index > viewControllerArray.count-1) {
            return nil
        }
        
        return viewControllerArray[index]
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        if (!completed) {
            return
        }
        
        let viewController = pageViewController.viewControllers.last as! TutorialPageViewController
        if let index = find(viewControllerArray, viewController) {
            pageControl.currentPage = index
        }
    }
    
}
