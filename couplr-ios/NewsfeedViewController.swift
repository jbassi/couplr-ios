//
//  NewsfeedViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 3/25/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class NewsfeedViewController: UIViewController {

    var headerView:NewsfeedHeaderView?
    var newsfeedTableView:UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView = NewsfeedHeaderView(frame: CGRectMake(view.frame.origin.x, kStatusBarHeight, view.bounds.size.width, 80))
        headerView!.headerLabel.text = "Newsfeed"
        headerView!.headerLabel.font = UIFont(name: "HelveticaNeue-Light", size: 32)
        
        let headerViewHeight = headerView!.frame.height + kStatusBarHeight + kProfileDetailViewBottomBorderHeight
        let newsfeedTableViewHeight = view.bounds.size.height - headerViewHeight - kCouplrNavigationBarButtonHeight
        
        newsfeedTableView = UITableView(frame: CGRectMake(0, headerViewHeight, view.bounds.size.width, newsfeedTableViewHeight))
        newsfeedTableView!.delegate = self
        newsfeedTableView!.dataSource = self
        newsfeedTableView!.registerClass(NewsfeedTableViewCell.self, forCellReuseIdentifier: "NewsfeedViewCell")

        view.addSubview(headerView!)
        view.addSubview(newsfeedTableView!)
    }
    
}

extension NewsfeedViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 20
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("NewsfeedViewCell", forIndexPath: indexPath) as NewsfeedTableViewCell
        
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return kTableViewCellHeight
    }
    
}
