//
//  MatchViewController.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/28/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit
import Parse

class MatchViewController: UIViewController {

    @IBOutlet weak var matchTitleLabel: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!

    var selectedTitle:MatchTitle? = nil
    var selectedUsers:[UInt64] = [UInt64]()
    var selectedIndices:[NSIndexPath] = [NSIndexPath]()

    var connectionData: NSMutableData = NSMutableData()
    var connection: NSURLConnection?
    var userPictures: [UInt64:String]?
    var socialGraphLoaded: Bool = false
    var loadingView: LoadingView?

    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        socialGraphController.delegate = self
        showLoadingScreen()
        // TODO Query titles and statuses simultaneously and retry when failing.
        matchGraphController.matches = MatchGraph()
        matchGraphController.fetchMatchTitles({
            (didError:Bool) -> Void in
            if !didError {
                self.socialGraphController.initializeGraph()
                let titleList:[MatchTitle] = self.matchGraphController.titleList()
                self.matchTitleLabel.setTitle(titleList[0].text, forState: UIControlState.Normal)
                self.selectedTitle = titleList[0]
            }
        })
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
            socialGraphController.updateRandomSample()
            selectedUsers.removeAll(keepCapacity: true)
            selectedIndices.removeAll(keepCapacity: true)
            collectionView.reloadData()
        }
    }

    func shuffleTitle() {
        let titleList:[MatchTitle] = matchGraphController.titleList()
        let randomIndex:Int = randomInt(titleList.count)
        selectedTitle = titleList[randomIndex]
        matchTitleLabel.setTitle(selectedTitle!.text, forState: UIControlState.Normal)

    }

    func showLoadingScreen() {
        loadingView = LoadingView.createLoadingScreenInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
    }

    func dismissLoadingScreen() {
        loadingView?.hideAnimated(true)
    }

}

// MARK: - UIPickerViewDelegate and UIPickerViewDataSource Methods

extension MatchViewController: UIPickerViewDelegate, UIPickerViewDataSource {

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return matchGraphController.titleList().count
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return matchGraphController.titleList()[row].text
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let titles:[MatchTitle] = matchGraphController.titleList()
        selectedTitle = titles[row]
        matchTitleLabel.setTitle(selectedTitle!.text, forState: UIControlState.Normal)
    }

}

// MARK: - UICollectionViewDelegate and UICollectionViewDataSource Methods

extension MatchViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return kMatchViewControllerCollectionViewNumberOfRows
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MatchViewCell", forIndexPath: indexPath) as ProfilePictureCollectionViewCell

        let randomSample:[UInt64] = socialGraphController.currentSample()
        if randomSample.count > 0 {
            let userID = randomSample[indexPath.row]
            cell.imageView.performRequestWith(profilePictureURLFromID(userID))
        }
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if selectedUsers.count < 2 {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as ProfilePictureCollectionViewCell
            let randomSample:[UInt64] = socialGraphController.currentSample()
            cell.userName = socialGraphController.nameFromId(randomSample[indexPath.row])
            selectedUsers.append(randomSample[indexPath.row])
            selectedIndices.append(indexPath)
            collectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: .None)
            if selectedUsers.count == 2 && selectedTitle != nil {
                matchGraphController.userDidMatch(selectedUsers[0], toSecondId: selectedUsers[1], withTitleId: selectedTitle!.id)
                log("Matching \(socialGraphController.nameFromId(selectedUsers[0])) with \(socialGraphController.nameFromId(selectedUsers[1])) for \"\(selectedTitle!.text)\"", withFlag: "~")
                selectedUsers.removeAll(keepCapacity: true)
                for index:NSIndexPath in selectedIndices {
                    collectionView.deselectItemAtIndexPath(index, animated: false)
                }
                selectedIndices.removeAll(keepCapacity: true)
                shufflePeople()
                shuffleTitle()
            }
        } else {
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        }
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as ProfilePictureCollectionViewCell
        let randomSample:[UInt64] = socialGraphController.currentSample()
        if let index = find(selectedUsers, randomSample[indexPath.row]) {
             selectedIndices.removeAtIndex(index)
             selectedUsers.removeAtIndex(index)
        }
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
    }

}

// MARK: - SocialGraphControllerDelegate Methods

extension MatchViewController: SocialGraphControllerDelegate {

    func socialGraphControllerDidLoadSocialGraph(graph: SocialGraph) {
        socialGraphLoaded = true
        dismissLoadingScreen()
        socialGraphController.updateRandomSample()
        collectionView.reloadData()
    }
}
