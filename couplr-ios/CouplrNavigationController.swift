//
//  CouplrViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 1/1/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import QuartzCore

class CouplrControllers {
    init() {
        profileViewController = nil
        matchViewController = nil
        newsfeedViewController = nil
        navigationController = nil
    }
    
    class var sharedInstance: CouplrControllers {
        struct CouplrControllersSingleton {
            static let instance = CouplrControllers()
        }
        return CouplrControllersSingleton.instance
    }
    
    func refreshProfileView() {
        profileViewController?.matchTableView?.reloadData()
    }

    func refreshNewsfeedView() {
        newsfeedViewController?.newsfeedTableView?.reloadData()
    }
    
    func showMatchViewLoadingScreen() {
        if let matchView = matchViewController {
            if matchView.isViewLoaded() {
                matchViewController?.showLoadingScreen()
            }
        }
    }
    
    func initializeMatchView() {
        if let matchView = matchViewController {
            if matchView.isViewLoaded() {
                matchViewController?.initializeSocialGraphAndMatchGraphControllers()
            }
        }
    }
    
    weak var profileViewController:ProfileViewController?
    weak var matchViewController:MatchViewController?
    weak var newsfeedViewController:NewsfeedViewController?
    weak var navigationController:CouplrNavigationController?
}

class CouplrNavigationController: UINavigationController {
    
    var navigationSelectionBar = UIView()
    var customNavigationBar = UIView()
    
    var animating: Bool = false
    var viewControllerArray = Array<UIViewController>()
    var buttonArray = Array<UIButton>()
    var pageViewController: UIPageViewController?
    var pageScrollView: UIScrollView?
    var lastPageIndex: NSInteger = 1
    var currentPageIndex: NSInteger = 1
    let matchViewButton = UIButton()
    let profileViewButton = UIButton()
    let newsfeedViewButton = UIButton()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = UIColor.whiteColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        setNavigationBarHidden(true, animated: false)
        
        buttonArray.append(profileViewButton)
        buttonArray.append(matchViewButton)
        buttonArray.append(newsfeedViewButton)
        
        setupNavigationBarButtons()
        setupPageViewController()
    }
    
    func resetNavigation() {
        pageViewController!.setViewControllers([viewControllerArray[1]], direction: .Forward, animated: false, completion: {(completed:Bool) in
            if completed {
                self.currentPageIndex = 1
                self.lastPageIndex = 1
                for (index:Int, button:UIButton) in enumerate(self.buttonArray) {
                    button.titleLabel?.font = index == self.lastPageIndex ? kCouplrNavigationButtonBoldFont : kCouplrNavigationButtonFont
                }
            }
        })
        setupNavigationSelectionBar(andAddSubview: false)
    }
    
    func setupPageViewController() {
        pageViewController = self.topViewController as? UIPageViewController
        pageViewController?.delegate = self
        pageViewController?.dataSource = self
        pageViewController?.setViewControllers([viewControllerArray[1]], direction: .Forward, animated: true, completion: nil)
        syncScrollView()
    }
    
    func setupNavigationBarButtons() {
        customNavigationBar.frame = CGRectMake(0, view.frame.size.height-kCouplrNavigationBarHeight, view.frame.size.width, kCouplrNavigationBarHeight)
        
        let buttonWidth = view.frame.width / CGFloat(viewControllerArray.count)
        profileViewButton.frame = CGRectMake(0, 0, buttonWidth, kCouplrNavigationBarButtonHeight)
        matchViewButton.frame = CGRectMake(buttonWidth, 0, buttonWidth, kCouplrNavigationBarButtonHeight)
        newsfeedViewButton.frame = CGRectMake(buttonWidth*2, 0, buttonWidth, kCouplrNavigationBarButtonHeight)
        
        matchViewButton.backgroundColor = UIColor.grayColor()
        profileViewButton.backgroundColor = UIColor.grayColor()
        newsfeedViewButton.backgroundColor = UIColor.grayColor()
        
        matchViewButton.addTarget(self, action: Selector("tapSegmentButton:"), forControlEvents: UIControlEvents.TouchUpInside)
        profileViewButton.addTarget(self, action: Selector("tapSegmentButton:"), forControlEvents: UIControlEvents.TouchUpInside)
        newsfeedViewButton.addTarget(self, action: Selector("tapSegmentButton:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        matchViewButton.setTitle(kMatchViewButtonTitle, forState: .Normal)
        matchViewButton.titleLabel?.font = kCouplrNavigationButtonBoldFont
        profileViewButton.setTitle(kProfileViewButtonTitle, forState: .Normal)
        profileViewButton.titleLabel?.font = kCouplrNavigationButtonFont
        newsfeedViewButton.setTitle(kNewsfeedViewButtonTitle, forState: .Normal)
        newsfeedViewButton.titleLabel?.font = kCouplrNavigationButtonFont
        
        matchViewButton.tag = kMatchViewButtonTag
        profileViewButton.tag = kProfileViewButtonTag
        newsfeedViewButton.tag = kNewsfeedViewButtonTag
        
        customNavigationBar.addSubview(profileViewButton)
        customNavigationBar.addSubview(matchViewButton)
        customNavigationBar.addSubview(newsfeedViewButton)
        view.addSubview(customNavigationBar)
        
        setupNavigationSelectionBar()
    }
    
    func setupNavigationSelectionBar(andAddSubview:Bool = true) {
        let selectionBarWidth = view.frame.width / CGFloat(viewControllerArray.count)
        navigationSelectionBar.frame = CGRectMake(selectionBarWidth, 0, selectionBarWidth, kCouplrNavigationBarSelectionIndicatorHeight)
        navigationSelectionBar.backgroundColor = UIColor.greenColor()
        navigationSelectionBar.alpha = 0.8
        navigationSelectionBar.layer.cornerRadius = kCouplrNavigationBarSelectionIndicatorCornerRadius
        if andAddSubview {
            customNavigationBar.addSubview(navigationSelectionBar)
        }
    }
    
    func syncScrollView() {
        for view in pageViewController?.view.subviews as! [UIView] {
            if view.isKindOfClass(UIScrollView) {
                pageScrollView = view as? UIScrollView
                pageScrollView!.delegate = self
            }
        }
    }
    
    func tapSegmentButton(button: UIButton) {
        let offset = button.tag - lastPageIndex
        
        if button.tag != currentPageIndex && !animating {
            if offset > 0 {
                // Positive direction
                animating = true
                for i in (currentPageIndex+1)...(button.tag) {
                    pageViewController!.setViewControllers([viewControllerArray[i]], direction: .Forward, animated: true, completion: {(completed:Bool) in
                        if completed {
                            self.currentPageIndex = i
                            self.buttonArray[self.lastPageIndex].titleLabel?.font = kCouplrNavigationButtonFont
                            self.lastPageIndex = button.tag
                            self.buttonArray[button.tag].titleLabel?.font = kCouplrNavigationButtonBoldFont
                            if i == button.tag {
                                self.animating = false
                            }
                            UserSessionTracker.sharedInstance.notify("tapped on \(self.pageNameFromIndex(i))")
                        }
                    })
                }
            } else if !animating {
                // Negative direction
                for i in reverse(button.tag...(currentPageIndex-1)) {
                    pageViewController!.setViewControllers([viewControllerArray[i]], direction: .Reverse, animated: true, completion: {(completed:Bool) in
                        if completed {
                            self.currentPageIndex = i
                            self.buttonArray[self.lastPageIndex].titleLabel?.font = kCouplrNavigationButtonFont
                            self.lastPageIndex = button.tag
                            self.buttonArray[button.tag].titleLabel?.font = kCouplrNavigationButtonBoldFont
                            if i == button.tag {
                                self.animating = false
                            }
                            UserSessionTracker.sharedInstance.notify("tapped on \(self.pageNameFromIndex(i))")
                        }
                    })
                }
            }
        }
    }
    
    func indexOfViewController(controller: UIViewController) -> NSInteger {
        for var index = 0; index < viewControllerArray.count; ++index {
            if controller == viewControllerArray[index] {
                return index
            }
        }
        return NSNotFound
    }
    
    func pageNameFromIndex(index:NSInteger) -> String {
        if index == 0 {
            return "Profile"
        } else if index == 1 {
            return "Matches"
        }
        return index == 2 ? "Newsfeed" : "No such page"
    }

}

extension CouplrNavigationController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        var index = indexOfViewController(viewController)
        
        if index == NSNotFound || index == 0 {
            return nil;
        }
        
        index--;
        
        return viewControllerArray[index]
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        var index = indexOfViewController(viewController)
        
        if index == NSNotFound {
            return nil
        }
        index++
        
        if index == viewControllerArray.count {
            return nil
        }
        return viewControllerArray[index]
    }
    
    func pageViewController(pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [AnyObject], transitionCompleted completed: Bool) {
        if completed {
            currentPageIndex = indexOfViewController(pageViewController.viewControllers.last as! UIViewController)
            self.buttonArray[lastPageIndex].titleLabel?.font = kCouplrNavigationButtonFont
            self.buttonArray[currentPageIndex].titleLabel?.font = kCouplrNavigationButtonBoldFont
            lastPageIndex = currentPageIndex
            UserSessionTracker.sharedInstance.notify("scrolled to \(self.pageNameFromIndex(currentPageIndex))")
        }
    }
    
}

extension CouplrNavigationController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        let xDistanceFromCenter = view.frame.size.width - pageScrollView!.contentOffset.x
        let xCoordinate = navigationSelectionBar.frame.size.width * CGFloat(currentPageIndex)
        
        navigationSelectionBar.frame = CGRectMake(xCoordinate-xDistanceFromCenter/CGFloat(viewControllerArray.count), navigationSelectionBar.frame.origin.y, navigationSelectionBar.frame.size.width, navigationSelectionBar.frame.size.height)
    }
    
}
