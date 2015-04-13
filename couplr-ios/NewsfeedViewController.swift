//
//  NewsfeedViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 3/25/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class NewsfeedViewController: UIViewController {

    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance
    var headerView:NewsfeedHeaderView?
    var newsfeedTableView:UITableView?
    var cachedNewsFeedMatches:[(MatchTuple, NSDate)]?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView = NewsfeedHeaderView(frame: CGRectMake(view.frame.origin.x, kStatusBarHeight, view.bounds.size.width, 80))
        headerView!.headerLabel.text = "Newsfeed"
        headerView!.headerLabel.font = UIFont(name: "HelveticaNeue-Light", size: 32)

        headerView!.nameSwitch.addTarget(self, action: "switchToggled:", forControlEvents: .ValueChanged)
        
        let headerViewHeight = headerView!.frame.height + kStatusBarHeight + kProfileDetailViewBottomBorderHeight
        let newsfeedTableViewHeight = view.bounds.size.height - headerViewHeight - kCouplrNavigationBarButtonHeight
        
        newsfeedTableView = UITableView(frame: CGRectMake(0, headerViewHeight, view.bounds.size.width, newsfeedTableViewHeight))
        newsfeedTableView!.delegate = self
        newsfeedTableView!.dataSource = self
        newsfeedTableView!.registerClass(NewsfeedTableViewCell.self, forCellReuseIdentifier: "NewsfeedViewCell")

        view.addSubview(headerView!)
        view.addSubview(newsfeedTableView!)
    }
    
    func newsFeedMatches() -> [(MatchTuple, NSDate)]? {
        if cachedNewsFeedMatches == nil {
            cachedNewsFeedMatches = matchGraphController.newsFeedMatches()
        }
        return self.cachedNewsFeedMatches
    }
    
    func showAllNamesInVisibleCells() {
        for cell in newsfeedTableView!.visibleCells() {
            let newsCell = cell as! NewsfeedTableViewCell
            if let matches:[(MatchTuple, NSDate)]? = newsFeedMatches() {
                let match:MatchTuple = matches![newsfeedTableView!.indexPathForCell(newsCell)!.row].0
                let nameForFirstId:String = socialGraphController.nameFromId(match.firstId, maxStringLength: 12)
                let nameForSecondId:String = socialGraphController.nameFromId(match.secondId, maxStringLength: 12)
                newsCell.addTransparentLayerWithName(nameForFirstId, rightName: nameForSecondId)
            }
        }
    }
    
    func hideAllNamesInVisibleCells() {
        for cell in newsfeedTableView!.visibleCells() {
            let newsCell = cell as! NewsfeedTableViewCell
            newsCell.removeTransparentLayer()
        }
    }
    
    func switchToggled(sender:UISwitch) {
        if sender.on {
            showAllNamesInVisibleCells()
            UserSessionTracker.sharedInstance.notify("toggled newsfeed names on")
        } else {
            hideAllNamesInVisibleCells()
            UserSessionTracker.sharedInstance.notify("toggled newsfeed names off")
        }
    }
    
}

extension NewsfeedViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        self.cachedNewsFeedMatches = nil
        let matches:[(MatchTuple, NSDate)]? = newsFeedMatches()
        
        if let numberOfMatches = matches?.count {
            if numberOfMatches > 0 {
                tableView.separatorStyle = .SingleLine
                headerView!.nameSwitch.enabled = true
                return 1
            } else {
                let messageLabel = UILabel(frame: CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height))
                messageLabel.text = kEmptyTableViewMessage
                messageLabel.textColor = UIColor.blackColor()
                messageLabel.numberOfLines = 0
                messageLabel.textAlignment = .Center
                messageLabel.sizeToFit()
                
                tableView.backgroundView = messageLabel;
                tableView.separatorStyle = .None;
                
                headerView!.nameSwitch.enabled = false
                
                return 0
            }
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.cachedNewsFeedMatches = nil
        let matches:[(MatchTuple, NSDate)]? = newsFeedMatches()
        return matches == nil ? 0 : matches!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NewsfeedViewCell", forIndexPath: indexPath) as! NewsfeedTableViewCell
        if let matchesAndUpdateTimes:[(MatchTuple, NSDate)]? = newsFeedMatches() {
            let (match:MatchTuple, updateTime:NSDate) = matchesAndUpdateTimes![indexPath.row]
            cell.cellText.text = matchGraphController.matchTitleFromId(match.titleId)!.text
            cell.selectionStyle = .None
            cell.leftCellImage.sd_setImageWithURL(profilePictureURLFromId(match.firstId), placeholderImage: UIImage(named: "sample-1049-at-sign"))
            cell.rightCellImage.sd_setImageWithURL(profilePictureURLFromId(match.secondId), placeholderImage: UIImage(named: "sample-1049-at-sign"))
            if headerView!.nameSwitch.on {
                let nameForFirstId:String = socialGraphController.nameFromId(match.firstId, maxStringLength: 12)
                let nameForSecondId:String = socialGraphController.nameFromId(match.secondId, maxStringLength: 12)
                cell.addTransparentLayerWithName(nameForFirstId, rightName: nameForSecondId)
            } else {
                cell.removeTransparentLayer()
            }
            let updateTimeInterval:NSTimeInterval = NSDate().timeIntervalSinceDate(updateTime)
            cell.dateLabel.text = "\(timeElapsedAsText(updateTimeInterval)) ago"
        }
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kTableViewCellHeight
    }
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        headerView!.nameSwitch.enabled = false
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        headerView!.nameSwitch.enabled = true
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        headerView!.nameSwitch.enabled = true
    }
    
}
