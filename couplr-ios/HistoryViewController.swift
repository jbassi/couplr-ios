//
//  HistoryViewController.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 5/20/15.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit
import Parse

class HistoryViewController: UIViewController {
    
    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance
    var headerView: MatchPairHeaderView?
    var historyTableView: UITableView?
    
    var cachedVoteHistory: [(MatchTuple, NSDate)]? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView = MatchPairHeaderView(frame: CGRectMake(view.frame.origin.x, kStatusBarHeight, view.bounds.size.width, 80))
        headerView!.headerLabel.text = "My votes"
        headerView!.headerLabel.font = UIFont(name: "HelveticaNeue-Light", size: 32)
        
        headerView!.nameSwitch.addTarget(self, action: "switchToggled:", forControlEvents: .ValueChanged)
        
        let headerViewHeight = headerView!.frame.height + kStatusBarHeight + kProfileDetailViewBottomBorderHeight
        let historyTableViewHeight = view.bounds.size.height - headerViewHeight - kCouplrNavigationBarButtonHeight
        
        historyTableView = UITableView(frame: CGRectMake(0, headerViewHeight, view.bounds.size.width, historyTableViewHeight))
        historyTableView!.delegate = self
        historyTableView!.dataSource = self
        historyTableView!.registerClass(MatchPairTableViewCell.self, forCellReuseIdentifier: "HistoryViewCell")
        
        view.addSubview(headerView!)
        view.addSubview(historyTableView!)
    }
    
    /**
     * Resets the cached list of matches the user has voted on.
     *
     * TODO Figure out why this is being called more times than it should when first
     * navigating to the history view.
     */
    func updateCachedVoteHistory() {
        cachedVoteHistory = matchGraphController.rootUserVoteHistory()
    }
    
    func voteHistory() -> [(MatchTuple, NSDate)] {
        if cachedVoteHistory == nil {
            updateCachedVoteHistory()
        }
        return cachedVoteHistory!
    }
    
    func showAllNamesInVisibleCells() {
        for cell in historyTableView!.visibleCells() {
            let newsCell = cell as! MatchPairTableViewCell
            let match: MatchTuple = voteHistory()[historyTableView!.indexPathForCell(newsCell)!.row].0
            let nameForFirstId: String = socialGraphController.nameFromId(match.firstId, maxStringLength: 12)
            let nameForSecondId: String = socialGraphController.nameFromId(match.secondId, maxStringLength: 12)
            newsCell.addTransparentLayerWithName(nameForFirstId, rightName: nameForSecondId)
        }
    }
    
    func hideAllNamesInVisibleCells() {
        for cell in historyTableView!.visibleCells() {
            let newsCell = cell as! MatchPairTableViewCell
            newsCell.removeTransparentLayer()
        }
    }
    
    func switchToggled(sender: UISwitch) {
        if sender.on {
            showAllNamesInVisibleCells()
            UserSessionTracker.sharedInstance.notify("toggled newsfeed names on")
        } else {
            hideAllNamesInVisibleCells()
            UserSessionTracker.sharedInstance.notify("toggled newsfeed names off")
        }
    }
}

extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        updateCachedVoteHistory()
        if voteHistory().count > 0 {
            tableView.separatorStyle = .SingleLine
            headerView!.nameSwitch.enabled = true
            return 1
        }
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        updateCachedVoteHistory()
        return voteHistory().count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("HistoryViewCell", forIndexPath: indexPath) as! MatchPairTableViewCell
        let (match: MatchTuple, updateTime: NSDate) = voteHistory()[indexPath.row]
        cell.cellText.text = matchGraphController.matchTitleFromId(match.titleId)!.text
        cell.selectionStyle = .None
        cell.leftCellImage.sd_setImageWithURL(profilePictureURLFromId(match.firstId), placeholderImage: UIImage(named: "unknown"))
        cell.rightCellImage.sd_setImageWithURL(profilePictureURLFromId(match.secondId), placeholderImage: UIImage(named: "unknown"))
        if headerView!.nameSwitch.on {
            let nameForFirstId: String = socialGraphController.nameFromId(match.firstId, maxStringLength: 12)
            let nameForSecondId: String = socialGraphController.nameFromId(match.secondId, maxStringLength: 12)
            cell.addTransparentLayerWithName(nameForFirstId, rightName: nameForSecondId)
        } else {
            cell.removeTransparentLayer()
        }
        let updateTimeInterval: NSTimeInterval = NSDate().timeIntervalSinceDate(updateTime)
        cell.dateLabel.text = "\(timeElapsedAsText(updateTimeInterval)) ago"
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
