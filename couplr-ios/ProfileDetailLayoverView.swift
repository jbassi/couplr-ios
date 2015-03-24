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
    var headerTitle: String?
    var imageName: String?
    let headerLabel: UILabel = UILabel()
    let titleImage: UIImageView = UIImageView()
    
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
        tableView.registerClass(ProfileViewControllerTableViewCell.self, forCellReuseIdentifier: "ProfileViewCell")
        
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
            
            headerLabel.text = headerTitle?
            titleImage.image = UIImage(named: imageName!)
            
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
    }

}

extension ProfileDetailLayoverView: UITableViewDelegate, UITableViewDataSource {

    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ProfileViewCell", forIndexPath: indexPath) as ProfileViewControllerTableViewCell
        
        return cell
    }
    
}
