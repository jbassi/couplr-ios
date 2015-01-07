//
//  CouplrViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 1/1/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import QuartzCore

class CouplrNavigationController: UINavigationController {
    
    var navigationSelectionBar = UIView()
    var customNavigationBar = UIView()
    
    var viewControllerArray = Array<UIViewController>()
    var pageViewController: UIPageViewController?
    var pageScrollView: UIScrollView?
    var currentPageIndex: NSInteger = 0
    let matchViewButton = UIButton()
    let profileViewButton = UIButton()
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        view.backgroundColor = UIColor.whiteColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        let storyboard = UIStoryboard(name: kStoryboardName, bundle: nil)
        let matchView = storyboard.instantiateViewControllerWithIdentifier(kStoryboardMatchViewControllerName) as MatchViewController
        let profileView = storyboard.instantiateViewControllerWithIdentifier(kStoryboardProfileViewControllerName) as ProfileViewController
        
        viewControllerArray.append(matchView)
        viewControllerArray.append(profileView)
        
        setupNavigationBarButtons()
        setupPageViewController()
    }
    
    func setupPageViewController() {
        pageViewController = self.topViewController as? UIPageViewController
        pageViewController?.delegate = self
        pageViewController?.dataSource = self
        pageViewController?.setViewControllers([viewControllerArray[0]], direction: .Forward, animated: true, completion: nil)
        syncScrollView()
    }
    
    func setupNavigationBarButtons() {
        customNavigationBar.frame = CGRectMake(0, view.frame.size.height-kCouplrNavigationBarHeight, view.frame.size.width, kCouplrNavigationBarHeight)
        
        let buttonWidth = view.frame.width / 2
        matchViewButton.frame = CGRectMake(0, 0, buttonWidth, kCouplrNavigationBarButtonHeight)
        profileViewButton.frame = CGRectMake(buttonWidth, 0, buttonWidth, kCouplrNavigationBarButtonHeight)
        
        matchViewButton.backgroundColor = UIColor.grayColor()
        profileViewButton.backgroundColor = UIColor.grayColor()
        
        matchViewButton.addTarget(self, action: Selector("tapSegmentButton:"), forControlEvents: UIControlEvents.TouchUpInside)
        profileViewButton.addTarget(self, action: Selector("tapSegmentButton:"), forControlEvents: UIControlEvents.TouchUpInside)
        
        matchViewButton.setTitle(kMatchViewButtonTitle, forState: .Normal)
        matchViewButton.titleLabel?.font = kCouplrNavigationButtonBoldFont
        profileViewButton.setTitle(kProfileViewButtonTitle, forState: .Normal)
        profileViewButton.titleLabel?.font = kCouplrNavigationButtonFont
        
        matchViewButton.tag = kMatchViewButtonTag
        profileViewButton.tag = kProfileViewButtonTag
        
        customNavigationBar.addSubview(matchViewButton)
        customNavigationBar.addSubview(profileViewButton)
        view.addSubview(customNavigationBar)
        
        setupNavigationSelectionBar()
    }
    
    func setupNavigationSelectionBar() {
        let selectionBarWidth = view.frame.width / 2
        navigationSelectionBar.frame = CGRectMake(0, 0, selectionBarWidth, kCouplrNavigationBarSelectionIndicatorHeight)
        navigationSelectionBar.backgroundColor = UIColor.greenColor()
        navigationSelectionBar.alpha = 0.8
        navigationSelectionBar.layer.cornerRadius = kCouplrNavigationBarSelectionIndicatorCornerRadius
        customNavigationBar.addSubview(navigationSelectionBar)
    }
    
    func syncScrollView() {
        for view in pageViewController?.view.subviews as [UIView] {
            if view.isKindOfClass(UIScrollView) {
                pageScrollView = view as? UIScrollView
                pageScrollView!.delegate = self
            }
        }
    }
    
    func tapSegmentButton(button: UIButton) {
        if button.tag == kProfileViewButtonTag {
            pageViewController!.setViewControllers([viewControllerArray[1]], direction: .Forward, animated: true, completion: {(completed:Bool) in
                if completed {
                    self.currentPageIndex = 1
                    self.matchViewButton.titleLabel?.font = kCouplrNavigationButtonFont
                    self.profileViewButton.titleLabel?.font = kCouplrNavigationButtonBoldFont
                }
            })
        } else if button.tag == kMatchViewButtonTag {
            pageViewController!.setViewControllers([viewControllerArray[0]], direction: .Reverse, animated: true, completion: {(completed:Bool) in
                if completed {
                    self.currentPageIndex = 0
                    self.matchViewButton.titleLabel?.font = kCouplrNavigationButtonBoldFont
                    self.profileViewButton.titleLabel?.font = kCouplrNavigationButtonFont
                }
            })
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
            currentPageIndex = indexOfViewController(pageViewController.viewControllers.last as UIViewController)
            if currentPageIndex == 0 {
                self.matchViewButton.titleLabel?.font = kCouplrNavigationButtonBoldFont
                self.profileViewButton.titleLabel?.font = kCouplrNavigationButtonFont
            } else if currentPageIndex == 1 {
                self.matchViewButton.titleLabel?.font = kCouplrNavigationButtonFont
                self.profileViewButton.titleLabel?.font = kCouplrNavigationButtonBoldFont
            }
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
