//
//  ProfileDetailLayoverView.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 3/23/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class ProfileDetailLayoverView: UIView {
    
    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance
    
    let transparentLayer: UIView = UIView()
    let blurView = FXBlurView()
    let dismissButton: UIButton = UIButton()
    let tableView: UITableView = UITableView()
    var title:MatchTitle? = nil
    var matchResult:[(UInt64,Int)]? = nil
    var recentMatchesResult:[MatchTuple]? = nil
    var imageName: String?
    let headerLabel: UILabel = UILabel()
    let titleImage: UIImageView = UIImageView()
    
    var useRecentMatches: Bool = false
    
    class func createDetailLayoverInView(view: UIView, animated: Bool) -> ProfileDetailLayoverView {
        let detailLayoverView = ProfileDetailLayoverView(frame: view.bounds)
        detailLayoverView.backgroundColor = UIColor.whiteColor()
        
        view.addSubview(detailLayoverView)
        return detailLayoverView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        transparentLayer.frame = frame
        transparentLayer.backgroundColor = kPickerTransparentLayerBackgroundColor
        transparentLayer.alpha = 0
        
        blurView.frame = frame
        blurView.blurEnabled = true
        blurView.tintColor = UIColor.clearColor()
        blurView.blurRadius = kPickerViewBlurViewBlurRadius
        blurView.alpha = 0
        
        let boxWidth: CGFloat = frame.width - 40
        let boxHeight: CGFloat = frame.height - 80
        
        let boxX = round((frame.size.width - boxWidth) / 2)
        let boxY = frame.size.height + boxHeight
        
        let boxRect = CGRect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)
        
        self.frame = boxRect
        self.layer.cornerRadius = 15.0
        
        dismissButton.frame = CGRectMake(0, self.frame.height-60, self.frame.width, 50)
        dismissButton.backgroundColor = UIColor.lightGrayColor()
        dismissButton.setTitle("Dismiss", forState: UIControlState.Normal)
        dismissButton.addTarget(self, action: "hideAnimated:", forControlEvents: UIControlEvents.TouchUpInside)
        
        tableView.frame = CGRectMake(0, 110, self.frame.width, self.frame.height-self.dismissButton.frame.height-120)
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.registerClass(ImageTitleTableViewCell.self, forCellReuseIdentifier: "RecentViewCell")
        tableView.registerClass(ImageTableViewCell.self, forCellReuseIdentifier: "ProfileViewCell")
        
        let headerView: UIView = UIView()
        headerView.frame = CGRectMake(0, 10, self.frame.width, 100)
        headerView.backgroundColor = UIColor.lightGrayColor()
        
        let imageX = (frame.size.width / 2) - (60 / 2) - (40 / 2)
        titleImage.frame = CGRectMake(imageX, 10, 50, 50)
        
        headerLabel.frame = CGRectMake(0, 60, self.frame.width, 40)
        headerLabel.textColor = UIColor.whiteColor()
        headerLabel.textAlignment = NSTextAlignment.Center
        headerLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 20)
        headerLabel.adjustsFontSizeToFitWidth = true
        headerView.addSubview(headerLabel)
        headerView.addSubview(titleImage)
        
        self.addSubview(dismissButton)
        self.addSubview(tableView)
        self.addSubview(headerView)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Animation Functions
    
    func showAnimated(animated: Bool) {
        if animated {
            superview!.insertSubview(blurView, belowSubview: self)
            superview!.insertSubview(transparentLayer, belowSubview: blurView)
            
            headerLabel.text = useRecentMatches ? "Recent Matches" : title?.text
            if let newImageName = imageName? {
                titleImage.image = UIImage(named: newImageName)
            }
            
            UIView.animateWithDuration(0.5, animations: {
                self.frame.origin.y = 50
            })
            UIView.animateWithDuration(kPickerShowAnimationDuration, animations: {
                self.transparentLayer.alpha = 1
                self.blurView.alpha = 1
                }, completion: nil)
        }
    }
    
    func hideAnimated(sender: UIButton!) {
        UIView.animateWithDuration(kPickerHideAnimationDuration, animations: {
            self.frame.origin.y = self.superview!.frame.size.height + self.frame.size.height
            self.transparentLayer.alpha = 0
            self.blurView.alpha = 0
            }, completion: { (completed:Bool) in
                self.blurView.removeFromSuperview()
                self.transparentLayer.removeFromSuperview()
                self.removeFromSuperview()
        })
        useRecentMatches = false
    }
    
    func recentMatches() -> [MatchTuple]? {
        if recentMatchesResult != nil {
            return recentMatchesResult!
        }
        let rootId:UInt64 = socialGraphController.rootId()
        recentMatchesResult = []
        let tuples:[MatchTuple] = matchGraphController.recentMatches().filter({
            (tupleAndTime:(MatchTuple,NSDate)) -> Bool in
            let tuple:MatchTuple = tupleAndTime.0
            let matchedWithId:UInt64 = tuple.firstId == rootId ? tuple.secondId : tuple.firstId
            return self.socialGraphController.containsUser(matchedWithId)
        }).map{ $0.0 }
        for u:MatchTuple in tuples {
            var shouldAddMatch:Bool = true
            for v:MatchTuple in recentMatchesResult! {
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
    
    func matchResultsForTitleId() -> [(UInt64,Int)]? {
        if self.title == nil {
            return nil
        }
        if self.matchResult != nil {
            return self.matchResult
        }
        let rootId:UInt64 = socialGraphController.rootId()
        let sortedMatches:[(Int,[(UInt64,Int)])] = matchGraphController.sortedMatchesForUser(rootId)
        let matchResult:[(UInt64,Int)] = sortedMatches.filter ({
            (titleAndMatches:(Int,[(UInt64,Int)])) -> Bool in
            return titleAndMatches.0 == self.title?.id
        })[0].1
        self.matchResult = matchResult
        return matchResult
    }
}

extension ProfileDetailLayoverView: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if useRecentMatches {
            self.recentMatchesResult = nil // Reset the recent matches upon rendering a new view.
            if let recentMatchesResult:[MatchTuple]? = recentMatches() {
                return recentMatchesResult!.count
            }
        } else {
            self.matchResult = nil // Reset the match result upon rendering a new view.
            if let matchResult:[(UInt64,Int)] = matchResultsForTitleId() {
                return matchResult.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if useRecentMatches {
            let rootId:UInt64 = socialGraphController.rootId()
            let cell = tableView.dequeueReusableCellWithIdentifier("RecentViewCell", forIndexPath: indexPath) as ImageTitleTableViewCell
            if let recentMatchesResult:[MatchTuple]? = recentMatches() {
                let matchTuple:MatchTuple = recentMatchesResult![indexPath.row]
                let matchedWithId:UInt64 = matchTuple.firstId == rootId ? matchTuple.secondId : matchTuple.firstId
                let profileImage = ProfilePictureImageView(pictureURL: profilePictureURLFromID(matchedWithId))
                cell.selectionStyle = .None
                cell.cellImage.layer.cornerRadius = 30
                cell.cellImage.layer.masksToBounds = true
                cell.cellText.text = socialGraphController.nameFromId(matchedWithId)
                cell.cellSubText.text = matchGraphController.matchTitleFromId(matchTuple.titleId)?.text
                func doLoadCellImage() {
                    cell.cellImage.image = profileImage.image
                }
                profileImage.performRequestWith(NSString(string: profilePictureURLFromID(matchedWithId)), doLoadCellImage)
            }
            return cell
            
        } else {
            let cell = tableView.dequeueReusableCellWithIdentifier("ProfileViewCell", forIndexPath: indexPath) as ImageTableViewCell
            if let matchResult:[(UInt64,Int)] = matchResultsForTitleId() {
                let (matchedWithId:UInt64, voteCount:Int) = matchResult[indexPath.row]
            
                cell.selectionStyle = .None
                cell.cellText.text = socialGraphController.nameFromId(matchedWithId, maxStringLength: 20)
                let profileImage = ProfilePictureImageView(pictureURL: profilePictureURLFromID(matchedWithId))
                cell.cellImage.image = UIImage(named: "sample-1049-at-sign")
                cell.cellImage.layer.cornerRadius = 30
                cell.cellImage.layer.masksToBounds = true
                func doLoadCellImage() {
                    cell.cellImage.image = profileImage.image
                }
                profileImage.performRequestWith(NSString(string: profilePictureURLFromID(matchedWithId)), doLoadCellImage)
                cell.numberOfTimesVotedLabel.text = Int(voteCount) > kProfileViewControllerMaximumNumberOfMatches ? kProfileViewControllerMaximumNumberOfMatchesString : voteCount.description
                
            }
            return cell
        }
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kTableViewCellHeight
    }
    
}
