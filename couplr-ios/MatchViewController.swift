//
//  MatchViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/28/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class MatchViewController: UIViewController {

    @IBOutlet weak var matchTitleLabel: UIButton!

    var testData = ["One Night Stand", "Prom King And Queen", "Likely To Get Married", "Should Not Be Together"]
    var selectedTitle: String?

    @IBOutlet weak var shufflePeople: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    var userFriends: NSArray?
    var connectionData: NSMutableData = NSMutableData()
    var connection: NSURLConnection?
    
    var requestHandler: CouplrFBRequestHandler = CouplrFBRequestHandler()
    let socialGraphController = SocialGraphController.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        socialGraphController.delegate = self
        matchTitleLabel.setTitle(testData[0], forState: UIControlState.Normal)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        requestHandler.delegate = self
        requestHandler.requestInvitableFriends()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func showButtonPressed() {
        let pickerView = PickerView.createPickerViewInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
        pickerView.dataSource = self
        pickerView.delegate = self
    }

}

// MARK: - UIPickerViewDelegate and UIPickerViewDataSource Methods

extension MatchViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return testData.count
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return testData[row]
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        matchTitleLabel.setTitle(testData[row], forState: UIControlState.Normal)
    }
    
}

// MARK: - UICollectionViewDelegate and UICollectionViewDataSource Methods

extension MatchViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return kMatchViewControllerCollectionViewNumberOfRows
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MatchViewCell", forIndexPath: indexPath) as ProfilePictureCollectionViewCell
        let url = "https://fbcdn-profile-a.akamaihd.net/hprofile-ak-xap1/v/t1.0-1/c4.51.632.632/s100x100/1456027_10202214203495049_399160996_n.jpg?oh=e5d3d24e0b534091c52e51e73ab28ed1&oe=55473607&__gda__=1428901135_cb8e264f335868cb522ca25e64a3af92"
        cell.imageView.performRequestWith(url)
        return cell
    }
    
}

// MARK: - SocialGraphControllerDelegate Methods

extension MatchViewController: SocialGraphControllerDelegate {
    
    func socialGraphControllerDidLoadSocialGraph(graph: SocialGraph) {
        graph.updateGenders()
    }
    
}


// MARK: - CouplrFBRequestHandlerProtocol

extension MatchViewController: CouplrFBRequestHandlerDelegate {
    
    func couplrFBRequestHandlerWillRecieveInvitableFriends() {
        // Display loading message
    }
    
    func couplrFBRequestHandlerDidRecieveInvitableFriends(array: NSArray) {
        userFriends = array
        collectionView.reloadData()
    }

}
