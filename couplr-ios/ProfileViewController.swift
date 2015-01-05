//
//  ProfileViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 9/13/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet weak var profilePicture: ProfilePictureImageView!
    
    let socialGraphController = SocialGraphController.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        let userID = socialGraphController.graph?.root
        profilePicture.performRequestWith(profilePictureURLFromID(userID!))
    }
    
}
