//
//  TutorialPageViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 4/17/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class TutorialPageViewController: UIViewController {

    let imageView: UIImageView = UIImageView()
    let titleLabel: UILabel = UILabel()
    var pageIndex: Int = -1
    var titleText: String = ""
    var imageFileName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        imageView.image = UIImage(named: imageFileName)
        
        view.addSubview(imageView)
        imageView.backgroundColor = UIColor.greenColor()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        imageView.frame = CGRectMake(view.frame.origin.x+10, view.frame.origin.y, view.frame.size.width-20, view.frame.size.height)
    }

}
