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

    var selectedTitle:MatchTitle? = nil
    var selectedRow:Int = 0
    var selectedUsers:[UInt64] = [UInt64]()
    var selectedIndices:[NSIndexPath] = [NSIndexPath]()

    var connectionData: NSMutableData = NSMutableData()
    var connection: NSURLConnection?
    var userPictures: [UInt64:String]?
    var socialGraphLoaded: Bool = false
    var loadingView: LoadingView?
    
    var collectionView:UICollectionView?
    let matchTitleLabel:UIButton = UIButton()
    let resetButton:UIButton = UIButton()
    let submitButton:UIButton = UIButton()
    let settingsButton:UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
    let toggleNamesSwitch:UISwitch = UISwitch()

    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frameWidth:CGFloat = view.frame.width
        let frameHeight:CGFloat = view.frame.height
        
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = CGSize(width: 100, height: 100)
        flowLayout.scrollDirection = UICollectionViewScrollDirection.Horizontal
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.minimumLineSpacing = 5
        let collectionViewHeight:CGFloat = 315.0
        let collectionViewWidth:CGFloat = 315.0
        let collectionViewX:CGFloat = (frameWidth-collectionViewWidth+5)/2
        let collectionViewY:CGFloat = (frameHeight-kStatusBarHeight-kCouplrNavigationBarButtonHeight-collectionViewHeight)/2+20
        let collectionViewFrame:CGRect = CGRectMake(collectionViewX, collectionViewY, collectionViewWidth, collectionViewHeight)
        collectionView = UICollectionView(frame: collectionViewFrame, collectionViewLayout: flowLayout)
        collectionView!.registerClass(ProfilePictureCollectionViewCell.self, forCellWithReuseIdentifier: "MatchViewCell")
        collectionView!.backgroundColor = UIColor.whiteColor()
        collectionView!.delegate = self
        collectionView!.dataSource = self
        collectionView!.allowsMultipleSelection = true
        
        let matchTitleLabelHeight:CGFloat = 40
        let matchTitleLabelWidth:CGFloat = collectionViewWidth - 5
        let matchTitleLabelY:CGFloat = collectionViewY - matchTitleLabelHeight - 5
        matchTitleLabel.frame = CGRectMake(collectionViewX, matchTitleLabelY, matchTitleLabelWidth, matchTitleLabelHeight)
        matchTitleLabel.layer.cornerRadius = 10
        matchTitleLabel.layer.masksToBounds = true
        matchTitleLabel.backgroundColor = UIColor.lightGrayColor()
        matchTitleLabel.addTarget(self, action: "showButtonPressed", forControlEvents: UIControlEvents.TouchUpInside)
        
        let buttonWidth:CGFloat = (collectionViewWidth / 3) - 5
        let buttonHeight:CGFloat = 40
        let buttonY:CGFloat = collectionViewY + collectionViewHeight + 5
        
        resetButton.frame = CGRectMake(collectionViewX, buttonY, buttonWidth, buttonHeight)
        resetButton.backgroundColor = UIColor.lightGrayColor()
        resetButton.setTitle("Shuffle", forState: .Normal)
        resetButton.layer.cornerRadius = 10
        resetButton.layer.masksToBounds = true
        resetButton.addTarget(self, action: "shuffleUnselectedMatches", forControlEvents: .TouchUpInside)
        
        submitButton.frame = CGRectMake(collectionViewX+buttonWidth+5, buttonY, buttonWidth, buttonHeight)
        submitButton.backgroundColor = UIColor.lightGrayColor()
        submitButton.setTitle("Submit", forState: .Normal)
        submitButton.layer.cornerRadius = 10
        submitButton.layer.masksToBounds = true
        submitButton.addTarget(self, action: "submitMatch", forControlEvents: .TouchUpInside)
        
        toggleNamesSwitch.frame.origin = CGPointMake(collectionViewX+((buttonWidth+5)*2), buttonY+5)
        toggleNamesSwitch.on = false
        toggleNamesSwitch.addTarget(self, action: "switchToggled:", forControlEvents: .ValueChanged)
        
        let settingsButtonX:CGFloat = toggleNamesSwitch.frame.origin.x + toggleNamesSwitch.frame.width + 15
        settingsButton.frame.origin = CGPointMake(settingsButtonX, buttonY+8)
        settingsButton.addTarget(self, action: "settingsToggled:", forControlEvents: .TouchUpInside)
        
        view.addSubview(collectionView!)
        view.addSubview(matchTitleLabel)
        view.addSubview(resetButton)
        view.addSubview(submitButton)
        view.addSubview(toggleNamesSwitch)
        view.addSubview(settingsButton)
        
        showLoadingScreen()
        initializeSocialGraphAndMatchGraphControllers()
    }
    
    func initializeSocialGraphAndMatchGraphControllers() {
        socialGraphController.delegate = self
        // TODO Retry query upon failure.
        socialGraphController.graphInitializeBeginTime = currentTimeInSeconds()
        matchGraphController.matches = MatchGraph()
        matchGraphController.fetchMatchTitles({
            (didError:Bool) -> Void in
            if !didError {
                self.socialGraphController.initializeGraph()
                let titleList:[MatchTitle] = self.matchGraphController.matchTitles()
                if titleList.count == 0 {
                    showLoginWithAlertViewErrorMessage("Our servers are overloaded! Try again later.", "Something went wrong.")
                } else {
                    self.matchTitleLabel.setTitle(titleList[0].text, forState: UIControlState.Normal)
                    self.selectedTitle = titleList[0]
                }
            } else {
                showLoginWithAlertViewErrorMessage("We could not connect to our servers from here!", "Something went wrong.")
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
            shuffleUnselectedMatches()
            UserSessionTracker.sharedInstance.notify("shuffled people")
        }
    }
    
    func switchToggled(sender: UISwitch) {
        if sender.on {
            showAllNames()
            UserSessionTracker.sharedInstance.notify("toggled names on")
        } else {
            hideAllNames()
            UserSessionTracker.sharedInstance.notify("toggled names off")
        }
    }
    
    func resetToggleNamesSwitchAndSelectedMatches() {
        hideAllNames()
        selectedTitle = nil
        selectedRow = 0
        selectedUsers.removeAll(keepCapacity: true)
        selectedIndices.removeAll(keepCapacity: true)
        toggleNamesSwitch.on = false
    }
    
    func settingsToggled(sender: UIButton) {
        CouplrControllers.sharedInstance.navigationController?.dismissViewControllerAnimated(true, completion: nil)
        UserSessionTracker.sharedInstance.notify("settings toggled")
    }
    
    func showAllNames() {
        for cell in collectionView!.visibleCells() as! [ProfilePictureCollectionViewCell] {
            let randomSample:[UInt64] = socialGraphController.currentSample()
            let indexPath = collectionView!.indexPathForCell(cell)!
            cell.userName = socialGraphController.nameFromId(randomSample[indexPath.row])
            cell.addTransparentLayer()
            cell.overrideLayerSelection = true
        }
    }
    
    func hideAllNames() {
        for cell in collectionView!.visibleCells() as! [ProfilePictureCollectionViewCell] {
            let randomSample:[UInt64] = socialGraphController.currentSample()
            let indexPath = collectionView!.indexPathForCell(cell)!
            cell.overrideLayerSelection = false
            if !contains(selectedIndices, indexPath) {
                cell.removeTransparentLayer()
            }
        }
    }

    func showButtonPressed() {
        let pickerView = PickerView.createPickerViewInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(selectedRow, inComponent: 0, animated: false)
        UserSessionTracker.sharedInstance.notify("opened title select")
    }

    func shuffleUnselectedMatches() {
        if socialGraphLoaded {
            var keepUsersAtIndices:[(UInt64, Int)] = []
            for (index:Int, userId:UInt64) in enumerate(selectedUsers) {
                keepUsersAtIndices.append(userId, selectedIndices[index].row)
            }
            socialGraphController.updateRandomSample(keepUsersAtIndices: keepUsersAtIndices)
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_main_queue()) {
                let indexPaths = self.collectionView?.indexPathsForVisibleItems()
                self.collectionView?.reloadItemsAtIndexPaths(indexPaths!.filter({ (index:AnyObject) -> Bool in
                    return find(self.selectedIndices, index as! NSIndexPath) == nil
                }))
                for index in self.selectedIndices {
                    self.collectionView?.selectItemAtIndexPath(index, animated: false, scrollPosition: .None)
                }
                
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
    
    func submitMatch() {
        if selectedUsers.count == 2 {
            matchGraphController.userDidMatch(selectedUsers[0], to: selectedUsers[1], withTitleId: selectedTitle!.id)
            log("Matching \(socialGraphController.nameFromId(selectedUsers[0])) with \(socialGraphController.nameFromId(selectedUsers[1])) for \"\(selectedTitle!.text)\"", withFlag: "~")
            selectedUsers.removeAll(keepCapacity: true)
            for index:NSIndexPath in selectedIndices {
                collectionView?.deselectItemAtIndexPath(index, animated: false)
            }
            selectedIndices.removeAll(keepCapacity: true)
            shuffleUnselectedMatches()
            shuffleTitle()
            UserSessionTracker.sharedInstance.notify("submitted match")
        } else {
            UserSessionTracker.sharedInstance.notify("attempted match submit (<2 users)")
        }
    }
    

    func shuffleTitle() {
        let titleList:[MatchTitle] = matchGraphController.matchTitles()
        let randomIndex:Int = randomInt(titleList.count)
        selectedTitle = titleList[randomIndex]
        selectedRow = randomIndex
        matchTitleLabel.setTitle(selectedTitle!.text, forState: UIControlState.Normal)
    }

    func showLoadingScreen(overrideExistingLoadingView:Bool = false) {
        if overrideExistingLoadingView || loadingView == nil {
            loadingView = LoadingView.createLoadingScreenInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
        }
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
        UserSessionTracker.sharedInstance.notify("selected title id \(titles[row].id)")
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
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("MatchViewCell", forIndexPath: indexPath) as! ProfilePictureCollectionViewCell
        cell.backgroundColor = UIColor.grayColor()
        let randomSample:[UInt64] = socialGraphController.currentSample()
        if randomSample.count > 0 {
            let userId = randomSample[indexPath.row]
            dispatch_async(dispatch_get_main_queue()) {
                cell.imageView.sd_setImageWithURL(profilePictureURLFromId(userId), placeholderImage: UIImage(named: "sample-1049-at-sign"))
            }
        }
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        UserSessionTracker.sharedInstance.notify("selected match \(indexPath.row)")
        if selectedUsers.count < 2 {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ProfilePictureCollectionViewCell
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
        UserSessionTracker.sharedInstance.notify("deselected match \(indexPath.row)")
        let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ProfilePictureCollectionViewCell
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
        UserSessionTracker.sharedInstance.notify("initialized social graph")
        socialGraphController.updateRandomSample()
        if isViewLoaded() {
            dispatch_async(dispatch_get_main_queue()) {
                self.collectionView!.reloadData()
            }
        }
    }
}
