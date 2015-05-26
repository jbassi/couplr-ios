//
//  CouplrViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 1/1/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import QuartzCore

class CouplrViewCoordinator {
    init() {
        profileViewController = nil
        matchViewController = nil
        newsfeedViewController = nil
        historyViewController = nil
        navigationController = nil
        loadingView = nil
    }
    
    class var sharedInstance: CouplrViewCoordinator {
        struct CouplrControllersSingleton {
            static let instance = CouplrViewCoordinator()
        }
        return CouplrControllersSingleton.instance
    }
    
    func refreshProfileView() {
        profileViewController?.matchTableView?.reloadData()
    }

    func refreshNewsfeedView() {
        newsfeedViewController?.newsfeedTableView?.reloadData()
    }

    func refreshHistoryView() {
        historyViewController?.updateCachedVoteHistory()
        historyViewController?.historyTableView?.reloadData()
    }
    
    func showMatchViewLoadingScreen() {
        if let matchView = matchViewController {
            if matchView.isViewLoaded() {
                tryToCreateAndShowLoadingView()
            }
        }
    }
    
    func didInitializeSocialNetwork() {
        matchViewController?.isInitializingSocialNetwork = false
    }
    
    func tryToCreateAndShowLoadingView(animated:Bool = true) -> Bool {
        let mainView = UIApplication.sharedApplication().delegate!.window!!
        if loadingViewIsActive {
            return false
        }
        loadingViewIsActive = true
        loadingView = LoadingView(frame: mainView.bounds)
        mainView.addSubview(loadingView!)
        loadingView!.showAnimated(animated)
        return true
    }
    
    func allowLoadingViewCreation() -> Bool {
        return !loadingViewIsActive
    }
    
    func dismissLoadingScreen() {
        loadingView?.hideAnimated()
        loadingViewIsActive = false
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
    weak var historyViewController:HistoryViewController?
    weak var navigationController:CouplrNavigationController?
    var loadingViewIsActive:Bool = false;
    var loadingView:LoadingView? = nil;
}

class CouplrNavigationController: UINavigationController {
    
    var navigationSelectionBar = UIView()
    var customNavigationBar = UIView()
    
    var animating: Bool = false
    var viewControllerArray = Array<UIViewController>()
    var buttonArray = Array<UIButton>()
    var pageViewController: UIPageViewController?
    var pageScrollView: UIScrollView?
    var lastPageIndex: NSInteger = kInitialPageIndex
    var currentPageIndex: NSInteger = kInitialPageIndex
    let matchViewButton = UIButton()
    let profileViewButton = UIButton()
    let newsfeedViewButton = UIButton()
    let historyViewButton = UIButton()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = UIColor.whiteColor()
        setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        buttonArray.append(profileViewButton)
        buttonArray.append(newsfeedViewButton)
        buttonArray.append(matchViewButton)
        buttonArray.append(historyViewButton)
        
        setupNavigationBarButtons()
        setupPageViewController()
    }
    
    func resetNavigation() {
        pageViewController!.setViewControllers([viewControllerArray[kInitialPageIndex]], direction: .Forward, animated: false, completion: {(completed:Bool) in
            if completed {
                self.currentPageIndex = kInitialPageIndex
                self.lastPageIndex = kInitialPageIndex
            }
        })
        setupNavigationSelectionBar(andAddSubview: false)
    }
    
    func setupPageViewController() {
        pageViewController = self.topViewController as? UIPageViewController
        pageViewController?.delegate = self
        pageViewController?.dataSource = self
        pageViewController?.setViewControllers([viewControllerArray[kInitialPageIndex]], direction: .Forward, animated: true, completion: nil)
        syncScrollView()
    }
    
    func setupNavigationBarButtons() {
        customNavigationBar.frame = CGRectMake(0, view.frame.size.height-kCouplrNavigationBarHeight, view.frame.size.width, kCouplrNavigationBarHeight)
        let buttonTags:[Int] = [kProfileViewButtonTag, kNewsfeedViewButtonTag, kMatchViewButtonTag, kHistoryViewButtonTag]
        let buttonIconNames:[String] = ["nav-profile", "nav-newsfeed", "nav-match", "nav-history"]
        let buttonWidth = view.frame.width / CGFloat(viewControllerArray.count)
        for (index:Int, button:UIButton) in enumerate(buttonArray) {
            let buttonOffset:CGFloat = buttonWidth * CGFloat(index)
            button.frame = CGRectMake(buttonOffset, 0, buttonWidth, kCouplrNavigationBarButtonHeight)
            button.backgroundColor = UIColor.grayColor()
            button.addTarget(self, action: Selector("tapSegmentButton:"), forControlEvents: UIControlEvents.TouchUpInside)
            let horizontalInset: CGFloat = (button.bounds.width - (button.bounds.height - kCouplrNavigationBarBottomInset - kCouplrNavigationBarTopInset)) / 2
            button.imageEdgeInsets = UIEdgeInsetsMake(kCouplrNavigationBarTopInset, horizontalInset, kCouplrNavigationBarBottomInset, horizontalInset)
            button.setImage(UIImage(named: buttonIconNames[index]), forState: .Normal)
            button.tag = buttonTags[index]
            customNavigationBar.addSubview(button)
        }
        view.addSubview(customNavigationBar)
        setupNavigationSelectionBar()
    }
    
    func setupNavigationSelectionBar(andAddSubview:Bool = true) {
        let selectionBarWidth = view.frame.width / CGFloat(viewControllerArray.count)
        navigationSelectionBar.frame = CGRectMake(selectionBarWidth*2, 0, selectionBarWidth, kCouplrNavigationBarSelectionIndicatorHeight)
        navigationSelectionBar.backgroundColor = kCouplrRedColor
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
            animating = true
            if offset > 0 {
                // Positive direction
                for i in (currentPageIndex+1)...(button.tag) {
                    pageViewController!.setViewControllers([viewControllerArray[i]], direction: .Forward, animated: true, completion: {(completed:Bool) in
                        if completed {
                            self.currentPageIndex = i
                            self.lastPageIndex = button.tag
                            if i == button.tag {
                                self.animating = false
                            }
                            UserSessionTracker.sharedInstance.notify("tapped on \(self.pageNameFromIndex(i))")
                        }
                    })
                }
            } else {
                // Negative direction
                for i in reverse(button.tag...(currentPageIndex-1)) {
                    pageViewController!.setViewControllers([viewControllerArray[i]], direction: .Reverse, animated: true, completion: {(completed:Bool) in
                        if completed {
                            self.currentPageIndex = i
                            self.lastPageIndex = button.tag
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
        if index == kProfileViewButtonTag {
            return "Profile"
        } else if index == kMatchViewButtonTag {
            return "Matches"
        } else if index == kNewsfeedViewButtonTag {
            return "Newsfeed"
        }
        return index == kHistoryViewButtonTag ? "History" : "No such page"
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
