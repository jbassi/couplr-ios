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
    @IBOutlet weak var collectionView: UICollectionView!
    
    var testData = ["One Night Stand", "Prom King And Queen", "Friendzoned Forever", "Zombie Apocalypse Survivors", "Married But Not Married", "Whipped", "Met At Band Camp", "Partners In Crime", "Met At Chess Club", "Opposites Attract", "PDA Overload", "Met At A Frat Party", "Met At Church", "Overly Attached", "One True Paring"]
    var selectedTitle: String?

    var connectionData: NSMutableData = NSMutableData()
    var connection: NSURLConnection?
    var userPictures: [UInt64:String]?
    var randomPeople: [UInt64:String]?
    var randomPeopleArray = Array<UInt64>()
    var socialGraphLoaded: Bool = false
    var selectedUsers = Array<UInt64>()
    
    let socialGraphController = SocialGraphController.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        socialGraphController.delegate = self
        matchTitleLabel.setTitle(testData[0], forState: UIControlState.Normal)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        self.resignFirstResponder()
        super.viewWillDisappear(animated)
    }

    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent) {
        if motion == UIEventSubtype.MotionShake {
            shufflePeople()
        }
    }
    
    @IBAction func showButtonPressed() {
        let pickerView = PickerView.createPickerViewInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
        pickerView.dataSource = self
        pickerView.delegate = self
    }
    
    @IBAction func shufflePeople() {
        if socialGraphLoaded {
            randomPeople = socialGraphController.graph!.randomSample()
            randomPeopleDictionaryToArray()
            selectedUsers.removeAll(keepCapacity: true)
            collectionView.reloadData()
        }
    }
    
    func randomPeopleDictionaryToArray() {
        if randomPeople != nil {
            randomPeopleArray.removeAll(keepCapacity: true)
            for (id, name) in randomPeople! {
                randomPeopleArray.append(id)
            }
        }
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
        
        if randomPeopleArray.count > 0 {
            let userID = randomPeopleArray[indexPath.row]
            cell.imageView.performRequestWith(profilePictureURLFromID(userID))
        }
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if selectedUsers.count < 2 {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as ProfilePictureCollectionViewCell
            cell.userName = randomPeople![randomPeopleArray[indexPath.row]]!
            selectedUsers.append(randomPeopleArray[indexPath.row])
            collectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: .None)
        } else {
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        }
    }
    
    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as ProfilePictureCollectionViewCell
        if let index = find(selectedUsers, randomPeopleArray[indexPath.row]) {
             selectedUsers.removeAtIndex(index)
        }
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
    }
    
}

// MARK: - SocialGraphControllerDelegate Methods

extension MatchViewController: SocialGraphControllerDelegate {
    
    func socialGraphControllerDidLoadSocialGraph(graph: SocialGraph) {
        socialGraphLoaded = true
        randomPeople = socialGraphController.graph!.randomSample()
        randomPeopleDictionaryToArray()
        collectionView.reloadData()
    }
    
    func socialGraphControllerDidLoadUserPictureURLs(users: [UInt64 : String]) {
        userPictures = users
    }
    
}
