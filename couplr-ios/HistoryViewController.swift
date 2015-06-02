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
        
        headerView!.nameToggleButton.addTarget(self, action: "namesToggled:", forControlEvents: .TouchUpInside)
        
        let headerViewHeight = headerView!.frame.height + kStatusBarHeight + kProfileDetailViewBottomBorderHeight
        let historyTableViewHeight = view.bounds.size.height - headerViewHeight - kCouplrNavigationBarButtonHeight
        
        historyTableView = UITableView(frame: CGRectMake(0, headerViewHeight, view.bounds.size.width, historyTableViewHeight))
        historyTableView!.delegate = self
        historyTableView!.dataSource = self
        historyTableView!.registerClass(MatchPairTableViewCell.self, forCellReuseIdentifier: "HistoryViewCell")
        historyTableView!.setEditing(true, animated: false)
        
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
            let matchCell = cell as! MatchPairTableViewCell
            let match: MatchTuple = voteHistory()[historyTableView!.indexPathForCell(matchCell)!.row].0
            let nameForFirstId: String = socialGraphController.nameFromId(match.firstId, maxStringLength: 12)
            let nameForSecondId: String = socialGraphController.nameFromId(match.secondId, maxStringLength: 12)
            matchCell.addTransparentLayerWithName(nameForFirstId, rightName: nameForSecondId)
        }
    }
    
    func hideAllNamesInVisibleCells() {
        for cell in historyTableView!.visibleCells() {
            let matchCell = cell as! MatchPairTableViewCell
            matchCell.removeTransparentLayer()
        }
    }
    
    func namesToggled(sender: UIButton) {
        sender.selected = !sender.selected
        if sender.selected {
            showAllNamesInVisibleCells()
            UserSessionTracker.sharedInstance.notify("toggled history names on")
        } else {
            hideAllNamesInVisibleCells()
            UserSessionTracker.sharedInstance.notify("toggled history names off")
        }
    }
}

extension HistoryViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        updateCachedVoteHistory()
        if voteHistory().count > 0 {
            tableView.backgroundView = nil
            tableView.separatorStyle = .SingleLine
            headerView!.nameToggleButton.enabled = true
            return 1
        }
        let messageLabel = UILabel(frame: CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height))
        messageLabel.text = kEmptyTableViewMessage
        messageLabel.textColor = UIColor.blackColor()
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .Center
        messageLabel.sizeToFit()
        tableView.backgroundView = messageLabel;
        tableView.separatorStyle = .None
        headerView!.nameToggleButton.enabled = false
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        updateCachedVoteHistory()
        return voteHistory().count
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        let match: MatchTuple = voteHistory()[indexPath.row].0
        matchGraphController.userDidUndoMatch(match.firstId, to: match.secondId, withTitleId: match.titleId, onComplete: { success in
            if success {
                let rootUserVoteHistory = self.matchGraphController.rootUserVoteHistory()
                if rootUserVoteHistory.count > 0 {
                    // This is the case where there are still other table cells remaining.
                    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: UITableViewRowAnimation.Fade)
                    self.cachedVoteHistory = rootUserVoteHistory
                } else {
                    // This is the case where the table is now empty.
                    tableView.deleteSections(NSIndexSet(index: indexPath.section), withRowAnimation: UITableViewRowAnimation.Fade)
                    self.cachedVoteHistory = []
                }
            }
        })
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("HistoryViewCell", forIndexPath: indexPath) as! MatchPairTableViewCell
        let (match: MatchTuple, updateTime: NSDate) = voteHistory()[indexPath.row]
        cell.setAdditionalLeftPaddingForCell(kAdditionalLeftPaddingForDeleteButton)
        cell.cellText.text = matchGraphController.matchTitleFromId(match.titleId)!.text
        cell.selectionStyle = .None
        cell.leftCellImage.sd_setImageWithURL(profilePictureURLFromId(match.firstId), placeholderImage: UIImage(named: "unknown"))
        cell.rightCellImage.sd_setImageWithURL(profilePictureURLFromId(match.secondId), placeholderImage: UIImage(named: "unknown"))
        if headerView!.nameToggleButton.selected {
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
        headerView!.nameToggleButton.enabled = false
    }
    
    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        headerView!.nameToggleButton.enabled = true
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        headerView!.nameToggleButton.enabled = true
    }
}
