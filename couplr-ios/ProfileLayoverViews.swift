//
//  ProfileLayoverViews.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 6/1/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class RecentMatchesLayoverView: AbstractProfileDetailLayoverView, UITableViewDelegate, UITableViewDataSource {
    
    class func createDetailLayoverInView(view: UIView, animated: Bool) -> RecentMatchesLayoverView {
        let detailLayoverView = RecentMatchesLayoverView(frame: view.bounds)
        detailLayoverView.backgroundColor = UIColor.whiteColor()
        
        view.addSubview(detailLayoverView)
        return detailLayoverView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func setTitleImage() -> Void {
        titleImage.image = nil // TODO Maybe add a title image for recent matches?
    }
    
    func setId(userId: UInt64) {
        self.userId = userId
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func getHeaderLabel() -> String {
        return "Recent matches"
    }
    
    func recentMatchesForCurrentUser() -> [MatchTuple]? {
        if lastRecentMatchesResult != nil && lastFetchedUserId == userId {
            return lastRecentMatchesResult!
        }
        lastRecentMatchesResult = []
        let tuples: [MatchTuple] = matchGraphController.sortedRecentMatchesForUser(userId).map { $0.0 }
        for match: MatchTuple in tuples {
            var shouldAddMatch: Bool = true
            for otherMatch: MatchTuple in lastRecentMatchesResult! {
                if match == otherMatch {
                    shouldAddMatch = false
                    break
                }
            }
            if shouldAddMatch {
                lastRecentMatchesResult!.append(match)
            }
        }
        lastFetchedUserId = userId
        return lastRecentMatchesResult
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.lastRecentMatchesResult = nil // Reset the recent matches upon rendering a new view.
        if let recentMatchesResult: [MatchTuple]? = recentMatchesForCurrentUser() {
            return recentMatchesResult!.count
        }
        return 0
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        self.lastRecentMatchesResult = nil // Reset the recent matches upon rendering a new view.
        if let recentMatchesResult: [MatchTuple]? = recentMatchesForCurrentUser() {
            if recentMatchesResult?.count > 0 {
                tableView.separatorStyle = .SingleLine
                return 1
            } else {
                let messageLabel = UILabel(frame: CGRectMake(0, 0, bounds.size.width, bounds.size.height))
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
        return 1
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("RecentViewCell", forIndexPath: indexPath) as! ImageTitleTableViewCell
        if let recentMatchesResult: [MatchTuple]? = recentMatchesForCurrentUser() {
            let matchTuple: MatchTuple = recentMatchesResult![indexPath.row]
            let matchedWithId: UInt64 = matchTuple.firstId == userId ? matchTuple.secondId : matchTuple.firstId
            cell.selectionStyle = .None
            cell.cellImage.layer.cornerRadius = 30
            cell.cellImage.layer.masksToBounds = true
            cell.cellText.text = socialGraphController.nameFromId(matchedWithId)
            cell.cellSubText.text = matchGraphController.matchTitleFromId(matchTuple.titleId)?.text
            cell.cellImage.sd_setImageWithURL(profilePictureURLFromId(matchedWithId), placeholderImage: UIImage(named: "unknown"))
        }
        return cell
    }
    
    var lastRecentMatchesResult: [MatchTuple]? = nil
    var lastFetchedUserId: UInt64 = 0
    var userId: UInt64 = 0
}

class MatchesByTitleLayoverView: AbstractProfileDetailLayoverView, UITableViewDelegate, UITableViewDataSource {
    
    class func createDetailLayoverInView(view: UIView, animated: Bool) -> MatchesByTitleLayoverView {
        let detailLayoverView = MatchesByTitleLayoverView(frame: view.bounds)
        detailLayoverView.backgroundColor = UIColor.whiteColor()
        
        view.addSubview(detailLayoverView)
        return detailLayoverView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setTitleImage() -> Void {
        titleImage.sd_setImageWithURL(profilePictureURLFromId(secondUser), placeholderImage: UIImage(named: "unknown"))
        titleImage.layer.cornerRadius = 25
        titleImage.layer.masksToBounds = true
    }
    
    override func getHeaderLabel() -> String {
        if socialGraphController.rootId() == firstUser {
            return "Me and \(socialGraphController.nameFromId(secondUser))"
        }
        return "\(socialGraphController.nameFromId(firstUser)) and \(socialGraphController.nameFromId(secondUser))"
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return matches.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ProfileViewCell", forIndexPath: indexPath) as! ImageTableViewCell
        let (titleId: Int, voteCount: Int) = matches[indexPath.row]
        cell.selectionStyle = .None
        let title: MatchTitle = matchGraphController.matchTitleFromId(titleId)!
        cell.cellText.text = title.text
        cell.cellImage.image = UIImage(named: title.picture)
        cell.numberOfTimesVotedLabel.text = Int(voteCount) > kProfileViewControllerMaximumNumberOfMatches ? kProfileViewControllerMaximumNumberOfMatchesString : voteCount.description
        return cell
    }
    
    var matches: [(Int, Int)] = []
    var secondUser: UInt64 = 0
    var firstUser: UInt64 = 0
}

