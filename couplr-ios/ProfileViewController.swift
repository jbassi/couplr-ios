//
//  ProfileViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 9/13/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    let imageNames = ["sample-1049-at-sign", "sample-1055-ticket", "sample-1067-enter-fullscreen", "sample-1079-fork-path", "sample-1082-merge"]
    
    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance
    var profileDetailView: ProfileDetailView?
    var matchTableView: UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()
        let rootID = socialGraphController.graph?.root
        
        profileDetailView = ProfileDetailView(frame: CGRectMake(0, kStatusBarHeight, view.bounds.size.width, kProfileViewControllerDetailViewHeight))
        profileDetailView!.profilePictureView.performRequestWith(profilePictureURLFromID(rootID!))
        profileDetailView!.profileNameLabel.text = socialGraphController.nameFromId(rootID!)
        
        let profileDetailViewTotalHeight = kProfileViewControllerDetailViewHeight + (kStatusBarHeight * 2)
        let matchTableViewHeight = view.bounds.size.height - profileDetailViewTotalHeight - kCouplrNavigationBarButtonHeight
        
        matchTableView = UITableView(frame: CGRectMake(0, profileDetailViewTotalHeight, view.bounds.size.width, matchTableViewHeight))
        matchTableView!.delegate = self
        matchTableView!.dataSource = self
        matchTableView!.registerClass(ProfileViewControllerTableViewCell.self, forCellReuseIdentifier: "ProfileViewCell")
        
        self.view.addSubview(matchTableView!)
        self.view.addSubview(profileDetailView!)
    }
    
}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let rootId:UInt64 = socialGraphController.rootId()
        if rootId == 0 {
            log("Warning: root user must be known before loading profile view.", withFlag:"?")
            return 0
        }
        return matchGraphController.sortedMatchesForUser(rootId).count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ProfileViewCell", forIndexPath: indexPath) as ProfileViewControllerTableViewCell
        let rootId:UInt64 = socialGraphController.rootId()
        if rootId == 0 {
            log("Warning: root user must be known before loading profile view.", withFlag:"?")
            return cell
        }
        let sortedMatches:[(Int,[(UInt64, Int)])] = matchGraphController.sortedMatchesForUser(rootId)
        let titleId:Int = sortedMatches[indexPath.row].0
        cell.textLabel?.text = matchGraphController.matchTitleFromId(titleId)?.text
        let imageName = imageNames[Int(arc4random_uniform(UInt32(imageNames.count)))]
        cell.imageView?.image = UIImage(named: imageName)
        var voteCount:Int = 0
        for (neighbor:UInt64, numVotes:Int) in sortedMatches[indexPath.row].1 {
            voteCount += numVotes
        }
        cell.numberOfTimesVotedLabel.text = Int(voteCount) > kProfileViewControllerMaximumNumberOfMatches ? kProfileViewControllerMaximumNumberOfMatchesString : String(voteCount)
        cell.selectionStyle = .None
        
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let pickerView = ProfileDetailLayoverView.createDetailLayoverInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
        let rootId:UInt64 = socialGraphController.rootId()
        if rootId == 0 {
            log("Warning: root user must be known before loading profile view.", withFlag:"?")
        }
        let sortedMatches:[(Int,[(UInt64, Int)])] = matchGraphController.sortedMatchesForUser(rootId)
        let titleId:Int = sortedMatches[indexPath.row].0
        
        pickerView.headerTitle = matchGraphController.matchTitleFromId(titleId)!.text
        pickerView.imageName = imageNames[Int(arc4random_uniform(UInt32(imageNames.count)))]
        pickerView.showAnimated(true)
    }
    
}
