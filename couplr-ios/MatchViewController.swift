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
    @IBOutlet weak var toggleNamesSwitch: UISwitch!

    var selectedTitle:MatchTitle? = nil
    var selectedRow:Int = 0
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
        toggleNamesSwitch.on = false
        toggleNamesSwitch.addTarget(self, action: "switchToggled:", forControlEvents: .ValueChanged)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.allowsMultipleSelection = true
        socialGraphController.delegate = self
        showLoadingScreen()
        // TODO Retry query upon failure.
        matchGraphController.matches = MatchGraph()
        socialGraphController.graphInitializeBeginTime = currentTimeInSeconds()
        matchGraphController.fetchMatchTitles({
            (didError:Bool) -> Void in
            if !didError {
                self.socialGraphController.initializeGraph()
                let titleList:[MatchTitle] = self.matchGraphController.matchTitles()
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
    
    func switchToggled(sender: UISwitch) {
        if sender.on {
            showAllNames()
        } else {
            hideAllNames()
        }
    }
    
    func showAllNames() {
        let cellCount = collectionView.visibleCells().count - 1
        for index in 0...cellCount {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let randomSample:[UInt64] = socialGraphController.currentSample()
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as ProfilePictureCollectionViewCell
            cell.userName = socialGraphController.nameFromId(randomSample[indexPath.row])
            cell.addTransparentLayer()
            cell.overrideLayerSelection = true
        }
    }
    
    func hideAllNames() {
        let cellCount = collectionView.visibleCells().count - 1
        for index in 0...cellCount {
            let indexPath = NSIndexPath(forRow: index, inSection: 0)
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as ProfilePictureCollectionViewCell
            cell.overrideLayerSelection = false
            if !contains(selectedIndices, indexPath) {
                cell.removeTransparentLayer()
            }
        }
    }

    @IBAction func showButtonPressed() {
        let pickerView = PickerView.createPickerViewInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(selectedRow, inComponent: 0, animated: false)
    }

    @IBAction func shufflePeople() {
        if socialGraphLoaded {
            socialGraphController.updateRandomSample()
            selectedUsers.removeAll(keepCapacity: true)
            selectedIndices.removeAll(keepCapacity: true)
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_main_queue()) {
                self.collectionView.reloadData()
                dispatch_async(dispatch_get_main_queue()) {
                    if self.toggleNamesSwitch.on {
                        self.showAllNames()
                    } else {
                        self.hideAllNames()
                    }
                }
            }
        }
    }
    
    @IBAction func submitMatch() {
        if selectedUsers.count == 2 {
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
    }
    

    func shuffleTitle() {
        let titleList:[MatchTitle] = matchGraphController.matchTitles()
        let randomIndex:Int = randomInt(titleList.count)
        selectedTitle = titleList[randomIndex]
        selectedRow = randomIndex
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
        return matchGraphController.matchTitles().count
    }

    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String! {
        return matchGraphController.matchTitles()[row].text
    }

    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        let titles:[MatchTitle] = matchGraphController.matchTitles()
        selectedTitle = titles[row]
        selectedRow = row
        matchTitleLabel.setTitle(selectedTitle!.text, forState: UIControlState.Normal)
    }
    
    func pickerView(pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 30
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView!) -> UIView {
        var label = view as? UILabel
        
        if label == nil {
            label = UILabel()
            let width = pickerView.rowSizeForComponent(component).width
            let height = pickerView.rowSizeForComponent(component).height
            label?.frame = CGRectMake(0, 0, width, height)
        }
        
        label!.adjustsFontSizeToFitWidth = true
        label!.textAlignment = NSTextAlignment.Center
        label!.font = UIFont.systemFontOfSize(22)
        label!.text = matchGraphController.matchTitles()[row].text
        
        return label!
    }

}

// MARK: - UICollectionViewDelegate and UICollectionViewDataSource Methods

extension MatchViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return kMatchViewControllerCollectionViewNumberOfRows
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MatchViewCell", forIndexPath: indexPath) as ProfilePictureCollectionViewCell
        cell.backgroundColor = UIColor.grayColor()

        let randomSample:[UInt64] = socialGraphController.currentSample()
        if randomSample.count > 0 {
            let userID = randomSample[indexPath.row]
            dispatch_async(dispatch_get_main_queue()) {
                cell.imageView.performRequestWith(profilePictureURLFromID(userID))
            }
        }
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if selectedUsers.count < 2 {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as ProfilePictureCollectionViewCell
            let randomSample:[UInt64] = socialGraphController.currentSample()
            cell.userName = socialGraphController.nameFromId(randomSample[indexPath.row])
            cell.backgroundColor = UIColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.8)
            selectedUsers.append(randomSample[indexPath.row])
            selectedIndices.append(indexPath)
            collectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: .None)
        } else {
            collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        }
    }

    func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as ProfilePictureCollectionViewCell
        cell.backgroundColor = UIColor.grayColor()
        let randomSample:[UInt64] = socialGraphController.currentSample()
        if let index = find(selectedUsers, randomSample[indexPath.row]) {
             selectedIndices.removeAtIndex(index)
             selectedUsers.removeAtIndex(index)
        }
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        if toggleNamesSwitch.on {
            cell.addTransparentLayer()
        }
    }

}

// MARK: - SocialGraphControllerDelegate Methods

extension MatchViewController: SocialGraphControllerDelegate {

    func socialGraphControllerDidLoadSocialGraph(graph: SocialGraph) {
        socialGraphLoaded = true
        dismissLoadingScreen()
        socialGraphController.updateRandomSample()
        dispatch_async(dispatch_get_main_queue()) {
            self.collectionView.reloadData()
        }
    }
}
