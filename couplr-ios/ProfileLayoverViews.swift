//
//  ProfileTableViews.swift
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
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func getHeaderLabel() -> String {
        return "Recent matches"
    }
    
    func recentMatches() -> [MatchTuple]? {
        if recentMatchesResult != nil {
            return recentMatchesResult!
        }
        let rootId: UInt64 = socialGraphController.rootId()
        recentMatchesResult = []
        let tuples: [MatchTuple] = matchGraphController.rootUserRecentMatches().filter({
            (tupleAndTime:(MatchTuple, NSDate)) -> Bool in
            let tuple: MatchTuple = tupleAndTime.0
            let matchedWithId: UInt64 = tuple.firstId == rootId ? tuple.secondId : tuple.firstId
            return self.socialGraphController.hasNameForUser(matchedWithId)
        }).map{ $0.0 }
        for u: MatchTuple in tuples {
            var shouldAddMatch: Bool = true
            for v: MatchTuple in recentMatchesResult! {
                if u == v {
                    shouldAddMatch = false
                }
            }
            if shouldAddMatch {
                recentMatchesResult!.append(u)
            }
        }
        return recentMatchesResult
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.recentMatchesResult = nil // Reset the recent matches upon rendering a new view.
        if let recentMatchesResult: [MatchTuple]? = recentMatches() {
            return recentMatchesResult!.count
        }
        return 0
    }
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        self.recentMatchesResult = nil // Reset the recent matches upon rendering a new view.
        if let recentMatchesResult: [MatchTuple]? = recentMatches() {
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
        let rootId: UInt64 = socialGraphController.rootId()
        let cell = tableView.dequeueReusableCellWithIdentifier("RecentViewCell", forIndexPath: indexPath) as! ImageTitleTableViewCell
        if let recentMatchesResult: [MatchTuple]? = recentMatches() {
            let matchTuple: MatchTuple = recentMatchesResult![indexPath.row]
            let matchedWithId: UInt64 = matchTuple.firstId == rootId ? matchTuple.secondId : matchTuple.firstId
            cell.selectionStyle = .None
            cell.cellImage.layer.cornerRadius = 30
            cell.cellImage.layer.masksToBounds = true
            cell.cellText.text = socialGraphController.nameFromId(matchedWithId)
            cell.cellSubText.text = matchGraphController.matchTitleFromId(matchTuple.titleId)?.text
            cell.cellImage.sd_setImageWithURL(profilePictureURLFromId(matchedWithId), placeholderImage: UIImage(named: "unknown"))
        }
        return cell
    }
    
    var recentMatchesResult: [MatchTuple]? = nil
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
        titleImage.sd_setImageWithURL(profilePictureURLFromId(userId), placeholderImage: UIImage(named: "unknown"))
        titleImage.layer.cornerRadius = 25
        titleImage.layer.masksToBounds = true
    }
    
    override func getHeaderLabel() -> String {
        return "Me and \(socialGraphController.nameFromId(userId))"
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
    var userId: UInt64 = 0
}

