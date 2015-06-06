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
    var headerView: MatchPairHeaderView?
    var newsfeedTableView: UITableView?
    var cachedNewsfeedMatches: [(MatchTuple, NSDate)]?
    
    var currentRevealedTableIndex: Int = -1
    var allowTableCellSelection: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView = MatchPairHeaderView(frame: CGRectMake(view.frame.origin.x, kStatusBarHeight, view.bounds.size.width, 80))
        headerView!.headerLabel.text = "Newsfeed"
        headerView!.headerLabel.font = UIFont(name: "HelveticaNeue-Light", size: 32)

        headerView!.nameToggleButton.addTarget(self, action: "namesToggled:", forControlEvents: .TouchUpInside)
        
        let headerViewHeight = headerView!.frame.height + kStatusBarHeight + kProfileDetailViewBottomBorderHeight
        let newsfeedTableViewHeight = view.bounds.size.height - headerViewHeight - kCouplrNavigationBarButtonHeight
        
        newsfeedTableView = UITableView(frame: CGRectMake(0, headerViewHeight, view.bounds.size.width, newsfeedTableViewHeight))
        newsfeedTableView!.delegate = self
        newsfeedTableView!.dataSource = self
        newsfeedTableView!.registerClass(NewsfeedTableViewCell.self, forCellReuseIdentifier: "NewsfeedViewCell")

        view.addSubview(headerView!)
        view.addSubview(newsfeedTableView!)
    }
    
    func newsfeedMatches() -> [(MatchTuple, NSDate)]? {
        if cachedNewsfeedMatches == nil {
            cachedNewsfeedMatches = matchGraphController.newsfeedMatches()
        }
        return self.cachedNewsfeedMatches
    }
    
    func showAllNamesInVisibleCells() {
        for cell in newsfeedTableView!.visibleCells() {
            let newsCell = cell as! NewsfeedTableViewCell
            if let matches: [(MatchTuple, NSDate)]? = newsfeedMatches() {
                let match: MatchTuple = matches![newsfeedTableView!.indexPathForCell(newsCell)!.row].0
                let nameForFirstId: String = socialGraphController.nameFromId(match.firstId, maxStringLength: 12)
                let nameForSecondId: String = socialGraphController.nameFromId(match.secondId, maxStringLength: 12)
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
    
    func namesToggled(sender: UIButton) {
        sender.selected = !sender.selected
        if sender.selected {
            headerView!.nameToggleButton.layer.borderColor = kCouplrRedColor.CGColor
            showAllNamesInVisibleCells()
            UserSessionTracker.sharedInstance.notify("toggled newsfeed names on")
        } else {
            headerView!.nameToggleButton.layer.borderColor = UIColor(white: 0.67, alpha: 1).CGColor
            hideAllNamesInVisibleCells()
            UserSessionTracker.sharedInstance.notify("toggled newsfeed names off")
        }
    }
}

extension NewsfeedViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        self.cachedNewsfeedMatches = nil
        let matches: [(MatchTuple, NSDate)]? = newsfeedMatches()
        
        if let numberOfMatches = matches?.count {
            if numberOfMatches > 0 {
                tableView.separatorStyle = .SingleLine
                tableView.backgroundView = nil
                headerView!.nameToggleButton.enabled = true
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
                
                headerView!.nameToggleButton.enabled = false
                
                return 0
            }
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.cachedNewsfeedMatches = nil
        let matches: [(MatchTuple, NSDate)]? = newsfeedMatches()
        if matches == nil {
            return 0
        }
        return matches!.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let row: Int = indexPath.row
        let cell = tableView.dequeueReusableCellWithIdentifier("NewsfeedViewCell", forIndexPath: indexPath) as! NewsfeedTableViewCell
        if let matchesAndUpdateTimes: [(MatchTuple, NSDate)]? = newsfeedMatches() {
            let (match: MatchTuple, updateTime: NSDate) = matchesAndUpdateTimes![indexPath.row]
            cell.setMatch(match)
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
        }
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if !allowTableCellSelection {
            return
        }
        allowTableCellSelection = false
        let row: Int = indexPath.row
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! NewsfeedTableViewCell
        if currentRevealedTableIndex != row {
            if cell.shouldAllowUserToVote() {
                cell.setButtonVisible(true)
                cellAtTableRow(currentRevealedTableIndex)?.hideButton()
                cell.revealButton(onComplete: { finished in
                    self.currentRevealedTableIndex = row
                    self.allowTableCellSelection = true
                })
            } else {
                cell.setButtonVisible(false)
                cell.shake()
                allowTableCellSelection = true
            }
        } else {
            if cell.isButtonHidden() {
                // The user has submitted a match here.
                currentRevealedTableIndex = -1
                cell.setButtonVisible(false)
                cell.shake()
                allowTableCellSelection = true
            } else {
                cellAtTableRow(currentRevealedTableIndex)?.hideButton(onComplete: { finished in
                    self.currentRevealedTableIndex = -1
                    self.allowTableCellSelection = true
                })
            }
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kTableViewCellHeight
    }
    
    func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        if self.currentRevealedTableIndex != -1 {
            cellAtTableRow(currentRevealedTableIndex)?.hideButton(onComplete: { finished in
                self.currentRevealedTableIndex = -1
            })
        }
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
    
    private func cellAtTableRow(row: Int) -> NewsfeedTableViewCell? {
        if row < 0 {
            return nil
        }
        return newsfeedTableView?.cellForRowAtIndexPath(NSIndexPath(forRow: row, inSection: 0)) as? NewsfeedTableViewCell
    }
}
