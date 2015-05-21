//
//  MatchViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/28/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit
import Parse

class HistoryViewController: UIViewController {
    
    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance
    var headerView:MatchPairHeaderView?
    var historyTableView:UITableView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        headerView = MatchPairHeaderView(frame: CGRectMake(view.frame.origin.x, kStatusBarHeight, view.bounds.size.width, 80))
        headerView!.headerLabel.text = "Submitted matches"
        headerView!.headerLabel.font = UIFont(name: "HelveticaNeue-Light", size: 32)
        
        headerView!.nameSwitch.addTarget(self, action: "switchToggled:", forControlEvents: .ValueChanged)
        
        let headerViewHeight = headerView!.frame.height + kStatusBarHeight + kProfileDetailViewBottomBorderHeight
        let historyTableViewHeight = view.bounds.size.height - headerViewHeight - kCouplrNavigationBarButtonHeight
        
        historyTableView = UITableView(frame: CGRectMake(0, headerViewHeight, view.bounds.size.width, historyTableViewHeight))
        historyTableView!.registerClass(MatchPairTableViewCell.self, forCellReuseIdentifier: "HistoryViewCell")
        
        view.addSubview(headerView!)
        view.addSubview(historyTableView!)
    }
}