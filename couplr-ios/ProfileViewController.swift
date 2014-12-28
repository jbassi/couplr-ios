//
//  ProfileViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 9/13/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController {
    
    @IBOutlet var profilePicture: FBProfilePictureView!

    override func viewDidLoad() {
        super.viewDidLoad()
        profilePicture = FBProfilePictureView(profileID: "me", pictureCropping: FBProfilePictureCropping.Square)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
