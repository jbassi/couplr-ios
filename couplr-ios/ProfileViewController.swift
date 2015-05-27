//
//  ProfileViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 9/13/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance
    var profileDetailView: ProfileDetailView?
    var matchTableView: UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()
        let rootId: UInt64 = socialGraphController.rootId()
        
        profileDetailView = ProfileDetailView(frame: CGRectMake(0, kStatusBarHeight, view.bounds.size.width, kProfileViewControllerDetailViewHeight))
        profileDetailView!.profileNameLabel.text = socialGraphController.nameFromId(rootId)
        profileDetailView!.recentMatchesButton.addTarget(self, action: "showRecentMatches:", forControlEvents: .TouchUpInside)
        profileDetailView!.profilePictureView.sd_setImageWithURL(profilePictureURLFromId(rootId), placeholderImage: UIImage(named: "unknown"))
        
        let profileDetailViewTotalHeight = kProfileViewControllerDetailViewHeight + (kStatusBarHeight * 2)
        let matchTableViewHeight = view.bounds.size.height - profileDetailViewTotalHeight - kCouplrNavigationBarButtonHeight
        
        matchTableView = UITableView(frame: CGRectMake(0, profileDetailViewTotalHeight, view.bounds.size.width, matchTableViewHeight))
        matchTableView!.delegate = self
        matchTableView!.dataSource = self
        matchTableView!.registerClass(ImageTableViewCell.self, forCellReuseIdentifier: "ProfileViewCell")
        
        self.view.addSubview(matchTableView!)
        self.view.addSubview(profileDetailView!)
    }
    
    func showRecentMatches(sender: UIButton) {
        let pickerView = ProfileDetailLayoverView.createDetailLayoverInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
        pickerView.useRecentMatches = true
        pickerView.showAnimated(true)
        UserSessionTracker.sharedInstance.notify("viewed recent matches")
    }
    
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        let rootId: UInt64 = socialGraphController.rootId()
        if rootId == 0 {
            log("Warning: root user must be known before loading profile view.", withFlag:"?")
            return 0
        }
        if matchGraphController.sortedMatchesForUser(rootId).count > 0 {
            tableView.separatorStyle = .SingleLine
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
            
            return 0
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rootId: UInt64 = socialGraphController.rootId()
        if rootId == 0 {
            log("Warning: root user must be known before loading profile view.", withFlag:"?")
            return 0
        }
        return matchGraphController.sortedMatchesForUser(rootId).count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ProfileViewCell", forIndexPath: indexPath) as! ImageTableViewCell
        let rootId: UInt64 = socialGraphController.rootId()
        if rootId == 0 {
            log("Warning: root user must be known before loading profile view.", withFlag:"?")
            return cell
        }
        let sortedMatches: [(Int,[(UInt64, Int)])] = matchGraphController.sortedMatchesForUser(rootId)
        let titleId: Int = sortedMatches[indexPath.row].0
        if let title: MatchTitle? = matchGraphController.matchTitleFromId(titleId) {
            cell.cellText.text = title!.text
            cell.cellImage.image = UIImage(named: title!.picture)
        }
        var voteCount: Int = 0
        for (neighbor: UInt64, numVotes: Int) in sortedMatches[indexPath.row].1 {
            voteCount += numVotes
        }
        cell.numberOfTimesVotedLabel.text = Int(voteCount) > kProfileViewControllerMaximumNumberOfMatches ? kProfileViewControllerMaximumNumberOfMatchesString : String(voteCount)
        cell.selectionStyle = .None
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kTableViewCellHeight
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let pickerView = ProfileDetailLayoverView.createDetailLayoverInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
        let rootId: UInt64 = socialGraphController.rootId()
        if rootId == 0 {
            log("Warning: root user must be known before loading profile view.", withFlag:"?")
        }
        let sortedMatches: [(Int,[(UInt64, Int)])] = matchGraphController.sortedMatchesForUser(rootId)
        let titleId: Int = sortedMatches[indexPath.row].0
        
        pickerView.title = matchGraphController.matchTitleFromId(titleId)
        pickerView.imageName = pickerView.title?.picture
        pickerView.showAnimated(true)
        UserSessionTracker.sharedInstance.notify("selected profile entry \(indexPath.row)")
    }
}
