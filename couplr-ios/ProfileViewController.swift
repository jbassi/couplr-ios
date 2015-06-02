//
//  ProfileViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 9/13/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    typealias MatchesByUser = [(UInt64, [(Int, Int)])]
    
    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance
    var profileDetailView: ProfileDetailView?
    var backButton: UIButton?
    var matchTableView: UITableView?
    var currentUserId: UInt64 = 0
    var cachedMatchCounts: [UInt64: MatchesByUser] = [UInt64: MatchesByUser]()

    override func viewDidLoad() {
        super.viewDidLoad()
        // By default, show the root user's profile.
        if currentUserId == 0 {
            currentUserId = socialGraphController.rootId()
        }
        
        let containerWidth: CGFloat = view.bounds.size.width
        let containerHeight: CGFloat = view.bounds.size.height - kStatusBarHeight - kCouplrNavigationBarHeight - kProfileBackButtonHeight
        
        let profileHeaderHeight: CGFloat = min(kProfileDefaultHeightRatio * containerHeight, kProfileHeaderMaximumSize)
        profileDetailView = ProfileDetailView(frame: CGRectMake(0, kStatusBarHeight + kProfileBackButtonHeight, containerWidth, profileHeaderHeight))
        profileDetailView!.profileNameLabel.text = socialGraphController.nameFromId(currentUserId, maxStringLength: 20)
        profileDetailView!.recentMatchesButton.addTarget(self, action: "showRecentMatches:", forControlEvents: .TouchUpInside)
        profileDetailView!.profilePictureView.sd_setImageWithURL(profilePictureURLFromId(currentUserId), placeholderImage: UIImage(named: "unknown"))
        
        matchTableView = UITableView(frame: CGRectMake(0, profileHeaderHeight + profileDetailView!.frame.origin.y, view.bounds.size.width, containerHeight - profileHeaderHeight))
        matchTableView!.delegate = self
        matchTableView!.dataSource = self
        matchTableView!.registerClass(ImageActionTableViewCell.self, forCellReuseIdentifier: "ProfileViewCell")
        
        backButton = UIButton()
        backButton!.frame = CGRectMake(0, kStatusBarHeight, 125, kProfileBackButtonHeight)
        backButton!.setTitle("‹ Back to my profile", forState: .Normal)
        backButton!.setTitleColor(kCouplrLinkColor, forState: .Normal)
        backButton!.titleLabel?.font = UIFont(name: "HelveticaNeue", size: 12)
        backButton!.addTarget(self, action: "resetProfileToRoot", forControlEvents: .TouchUpInside)
        backButton!.hidden = true
        
        self.view.addSubview(matchTableView!)
        self.view.addSubview(profileDetailView!)
        self.view.addSubview(backButton!)
    }
    
    func showRecentMatches(sender: UIButton) {
        let pickerView = RecentMatchesLayoverView.createDetailLayoverInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
        pickerView.setId(currentUserId)
        pickerView.showAnimated(true)
        UserSessionTracker.sharedInstance.notify("viewed recent matches")
    }
    
    func resetProfileToRoot() {
        setUserId(socialGraphController.rootId())
    }
    
    func setUserId(userId: UInt64) {
        profileDetailView!.profilePictureView.sd_setImageWithURL(profilePictureURLFromId(userId), placeholderImage: UIImage(named: "unknown"))
        profileDetailView!.profileNameLabel.text = socialGraphController.nameFromId(userId, maxStringLength: 20)
        currentUserId = userId
        matchGraphController.doAfterLoadingMatchesForId(userId, onComplete: { (success) in
            if !success {
                return
            }
            self.backButton?.hidden = userId == self.socialGraphController.rootId()
            self.cachedMatchCounts[userId] = self.matchGraphController.sortedMatchesForUserByUserId(userId)
            self.matchTableView?.reloadData()
        })
    }
    
    func matchCountsByUserForUser(userId: UInt64) -> MatchesByUser {
        if !socialGraphController.hasNameForUser(userId) {
            return []
        }
        if cachedMatchCounts[userId] == nil {
            cachedMatchCounts[userId] = matchGraphController.sortedMatchesForUserByUserId(userId)
        }
        return cachedMatchCounts[userId]!
    }
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func didSelectProfile(sender: UIButton) {
        let selectedButton: UserIdButton = sender as! UserIdButton
        setUserId(selectedButton.userId)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if matchCountsByUserForUser(currentUserId).count > 0 {
            tableView.separatorStyle = .SingleLine
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
        
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matchCountsByUserForUser(currentUserId).count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ProfileViewCell", forIndexPath: indexPath) as! ImageActionTableViewCell
        let sortedMatches: MatchesByUser = matchCountsByUserForUser(currentUserId)
        let userId: UInt64 = sortedMatches[indexPath.row].0
        cell.actionButton.setId(userId)
        cell.actionButton.addTarget(self, action: "didSelectProfile:", forControlEvents: .TouchUpInside)
        cell.cellText.text = socialGraphController.nameFromId(userId, maxStringLength: 20)
        cell.cellImage.sd_setImageWithURL(profilePictureURLFromId(userId), placeholderImage: UIImage(named: "unknown"))
        cell.cellImage.layer.masksToBounds = true
        cell.cellImage.layer.cornerRadius = 30
        cell.cellImage.layer.borderColor = UIColor(white: 0.67, alpha: 1).CGColor
        cell.cellImage.layer.borderWidth = 0.5

        var voteCount: Int = 0
        for (title: Int, numVotes: Int) in sortedMatches[indexPath.row].1 {
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
        let pickerView = MatchesByTitleLayoverView.createDetailLayoverInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
        let sortedMatches: MatchesByUser = matchCountsByUserForUser(currentUserId)
        pickerView.firstUser = currentUserId
        pickerView.secondUser = sortedMatches[indexPath.row].0
        for (user: UInt64, list) in sortedMatches {
            if user == pickerView.secondUser {
                pickerView.matches = list
            }
        }
        pickerView.showAnimated(true)
        UserSessionTracker.sharedInstance.notify("selected profile entry \(indexPath.row)")
    }
}
