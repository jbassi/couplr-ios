//
//  TutorialPageViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 4/17/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class TutorialPageViewController: UIViewController {

    let descriptionLabel: UILabel = UILabel()
    let phoneView: UIImageView = UIImageView()
    let screenView: UIImageView = UIImageView()
    let titleLabel: UILabel = UILabel()
    var pageIndex: Int = -1
    var descriptionText: String = ""
    var screenFileName: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phoneView.image = kTutorialPhoneImage
        screenView.image = UIImage(named: screenFileName)
        descriptionLabel.text = descriptionText
        descriptionLabel.numberOfLines = 0
        descriptionLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        descriptionLabel.textAlignment = NSTextAlignment.Center
        descriptionLabel.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        view.addSubview(descriptionLabel)
        view.addSubview(phoneView)
        phoneView.addSubview(screenView)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let descriptionHeight = view.bounds.size.height * kTutorialDescriptionHeightRatio
        let phoneContainerSize = CGSizeMake(view.bounds.size.width, view.bounds.size.height - descriptionHeight)
        let scaledPhoneSize = kTutorialPhoneSize.resizeDimensionsToFit(phoneContainerSize)
        let horizontalPadding = (view.bounds.size.width - scaledPhoneSize.width) / 2
        descriptionLabel.frame = CGRectMake(kTutorialDescriptionHorizontalPadding, 0, phoneContainerSize.width - 2 * kTutorialDescriptionHorizontalPadding, descriptionHeight)
        screenView.frame = CGRectMake(kTutorialPhoneContentRect.origin.x * scaledPhoneSize.width, kTutorialPhoneContentRect.origin.y * scaledPhoneSize.height,
            kTutorialPhoneContentRect.size.width * scaledPhoneSize.width, kTutorialPhoneContentRect.size.height * scaledPhoneSize.height)
        phoneView.frame = CGRectMake(horizontalPadding, view.frame.origin.y + descriptionHeight, scaledPhoneSize.width, scaledPhoneSize.height)
    }

}
