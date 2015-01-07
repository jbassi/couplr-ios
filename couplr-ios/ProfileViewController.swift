//
//  ProfileViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 9/13/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    let testData = ["One Night Stand", "Prom King And Queen", "Friendzoned Forever", "Zombie Apocalypse Survivors", "Married But Not Married", "Whipped", "Met At Band Camp", "Partners In Crime", "Met At Chess Club", "Opposites Attract", "PDA Overload", "Met At A Frat Party", "Met At Church", "Overly Attached", "One True Paring"]
    let imageNames = ["sample-1049-at-sign", "sample-1055-ticket", "sample-1067-enter-fullscreen", "sample-1079-fork-path", "sample-1082-merge"]
    
    let socialGraphController = SocialGraphController.sharedInstance
    var profileDetailView: ProfileDetailView?
    var matchTableView: UITableView?

    override func viewDidLoad() {
        super.viewDidLoad()
        let rootID = socialGraphController.graph?.root
        
        profileDetailView = ProfileDetailView(frame: CGRectMake(0, kStatusBarHeight, view.bounds.size.width, kProfileViewControllerDetailViewHeight))
        profileDetailView!.profilePictureView.performRequestWith(profilePictureURLFromID(rootID!))
        profileDetailView!.profileNameLabel.text = socialGraphController.graph?.names[rootID!]
        
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
        return 50
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ProfileViewCell", forIndexPath: indexPath) as ProfileViewControllerTableViewCell
        cell.textLabel?.text = testData[indexPath.row % testData.count]
        cell.imageView?.image = UIImage(named: imageNames[Int(arc4random_uniform(UInt32(imageNames.count)))])
        let randomMatchNumber = arc4random_uniform(UInt32(150))
        cell.numberOfTimesVotedLabel.text = Int(randomMatchNumber) > kProfileViewControllerMaximumNumberOfMatches ? kProfileViewControllerMaximumNumberOfMatchesString : String(randomMatchNumber)
        cell.selectionStyle = .None
        
        return cell
    }
    
}
