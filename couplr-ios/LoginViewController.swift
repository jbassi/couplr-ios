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
    var viewControllerArray = Array<UIViewController>()
    var pageViewController: UIPageViewController!

    var viewDidAppear: Bool = false
    var viewIsVisible: Bool = false

    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        loginView.delegate = self
        loginView.readPermissions = ["user_friends", "user_status", "user_posts", "user_photos"]
        let loginViewX:CGFloat = (view.bounds.width / 2) - (loginView.bounds.width / 2)
        let loginViewY:CGFloat = view.bounds.height - 40 - (loginView.bounds.height / 2)
        loginView.frame.origin = CGPointMake(loginViewX, loginViewY)
        
        continueButton.hidden = true
        let continueButtonY:CGFloat = (view.bounds.height / 2) + (loginView.frame.height / 2)
        continueButton.frame = CGRectMake(0, continueButtonY, view.frame.size.width, 50)
        continueButton.titleLabel?.adjustsFontSizeToFitWidth = true
        continueButton.titleLabel?.textAlignment = .Center
        continueButton.setTitleColor(UIColor.blueColor(), forState: .Normal)
        continueButton.addTarget(self, action: "continueButtonPressed:", forControlEvents: .TouchUpInside)
        
        let pageOne = TutorialPageViewController()
        pageOne.pageIndex = 0
        pageOne.imageFileName = "1"
        let pageTwo = TutorialPageViewController()
        pageTwo.pageIndex = 1
        pageTwo.imageFileName = "2"
        let pageThree = TutorialPageViewController()
        pageThree.pageIndex = 2
        pageThree.imageFileName = "3"
        
        viewControllerArray.append(pageOne)
        viewControllerArray.append(pageTwo)
        viewControllerArray.append(pageThree)
        
        let pageControlX:CGFloat = (view.bounds.width / 2) - (pageControl.bounds.width / 2)
        let pageControlY:CGFloat = loginViewY - 20
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
        
        view.backgroundColor = UIColor.whiteColor()
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        view.addSubview(pageControl)
        view.addSubview(loginView)
        view.addSubview(continueButton)
        
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
    
    func hideTutorial() {
        pageViewController.removeFromParentViewController()
        pageViewController.view.removeFromSuperview()
        pageControl.removeFromSuperview()
        let loginViewY:CGFloat = (view.bounds.height / 2) - (loginView.bounds.height / 2)
        loginView.frame.origin.y = loginViewY
    }
    
    func showTutorial() {
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        view.addSubview(pageControl)
        
        let loginViewY:CGFloat = view.bounds.height - 40 - (loginView.bounds.height / 2)
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
            loadAppViewsAndPresentNavigationController()
        }
    }
    
    func loginViewShowingLoggedOutUser(loginView: FBLoginView!) {
        continueButton.hidden = true
        showTutorial()
    }
    
    func loginViewFetchedUserInfo(loginView : FBLoginView!, user: FBGraphUser) {
        var buttonTitle: String = "Continue As \(user.name)..."
        continueButton.setTitle(buttonTitle, forState: UIControlState.Normal)
        continueButton.hidden = false
        hideTutorial()
    }
    
    func loginView(loginView : FBLoginView!, handleError:NSError) {
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
