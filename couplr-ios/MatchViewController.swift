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

    var selectedTitle: MatchTitle? = nil
    var selectedRow: Int = 0
    var selectedUsers: [UInt64] = [UInt64]()
    var selectedIndices: [NSIndexPath] = [NSIndexPath]()

    var connectionData: NSMutableData = NSMutableData()
    var connection: NSURLConnection?
    var userPictures: [UInt64: String]?
    var socialGraphLoaded: Bool = false
    
    var isInitializingSocialNetwork = false
    
    var collectionView: UICollectionView?
    let matchTitle: UIButton = UIButton()
    let shuffleButton: UIButton = UIButton()
    let submitButton: UIButton = UIButton()
    let settingsButton: UIButton = UIButton.buttonWithType(UIButtonType.DetailDisclosure) as! UIButton
    let toggleNamesButton: UIButton = UIButton()
    let titleSelectButton: UIButton = UIButton()

    let socialGraphController = SocialGraphController.sharedInstance
    let matchGraphController = MatchGraphController.sharedInstance

    var matchCellSideLength: CGFloat = 100
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let frameWidth: CGFloat = view.frame.width
        let frameHeight: CGFloat = view.frame.height
        let outerMatchViewRect: CGRect = CGRectMake(0, kStatusBarHeight, frameWidth, frameHeight - kCouplrNavigationBarHeight - kStatusBarHeight).withMargin(horizontal: 8)
        var (buttonBounds, matchBounds, titleBounds) = computeComponentRects(frameHeight, outerBoundingRect: outerMatchViewRect)
        if titleBounds.origin.y > kMatchViewTitleHeight {
            (buttonBounds, matchBounds, titleBounds) = computeComponentRects(frameHeight, outerBoundingRect: outerMatchViewRect, marginBetweenElements: (titleBounds.origin.y - kMatchViewTitleHeight) / 4)
        }
        
        // Set up and position the match title label.
        matchTitle.frame = titleBounds
        matchTitle.setTitleColor(kCouplrLinkColor, forState: .Normal)
        // TODO Dynamically set the font size to expand to the maximum height and width.
        matchTitle.titleLabel?.font = UIFont(name: "HelveticaNeue-Light", size: 20)
        matchTitle.addTarget(self, action: "showTitleSelect", forControlEvents: .TouchUpInside)
        
        // Set up and position the match collection view.
        let flowLayout = UICollectionViewFlowLayout()
        matchCellSideLength = (matchBounds.size.height - 10) / 3
        flowLayout.itemSize = CGSize(width: matchCellSideLength, height: matchCellSideLength)
        flowLayout.minimumInteritemSpacing = 5
        flowLayout.minimumLineSpacing = 5
        collectionView = UICollectionView(frame: matchBounds, collectionViewLayout: flowLayout)
        collectionView!.backgroundColor = UIColor.whiteColor()
        collectionView!.registerClass(ProfilePictureCollectionViewCell.self, forCellWithReuseIdentifier: "MatchViewCell")
        collectionView!.delegate = self
        collectionView!.dataSource = self
        collectionView!.allowsMultipleSelection = true

        // Set up and position the buttons.
        let buttons: [UIButton] = [toggleNamesButton, titleSelectButton, shuffleButton, submitButton]
        let buttonImageNames: [String?] = ["matchview-names", nil, "matchview-shuffle", "matchview-match"]
        let buttonActionNames: [Selector] = [Selector("namesToggled:"), Selector("showTitleSelect"), Selector("shuffleUnselectedMatches"), Selector("submitMatch")]
        let buttonSideLength: CGFloat = buttonBounds.width / CGFloat(buttons.count)
        let buttonInsets: CGFloat = 0.15 * buttonSideLength
        for (index: Int, button: UIButton) in enumerate(buttons) {
            button.frame = CGRectMake(buttonBounds.origin.x + CGFloat(index) * buttonSideLength, buttonBounds.origin.y, buttonSideLength, buttonSideLength).withMargin(horizontal: 3, vertical: 3)
            button.backgroundColor = UIColor.whiteColor()
            button.layer.cornerRadius = buttonSideLength / 2 - 1
            button.layer.borderColor = UIColor(white: 0.67, alpha: 1).CGColor
            button.layer.borderWidth = 0.5
            if buttonImageNames[index] != nil {
                button.setImage(UIImage(named: buttonImageNames[index]!), forState: .Normal)
            } else {
                button.setImage(nil, forState: .Normal)
            }
            button.imageEdgeInsets = UIEdgeInsetsMake(buttonInsets, buttonInsets, buttonInsets, buttonInsets)
            button.clipsToBounds = true
            button.addTarget(self, action: buttonActionNames[index], forControlEvents: .TouchUpInside)
            view.addSubview(button)
        }
        view.addSubview(collectionView!)
        view.addSubview(matchTitle)
        initializeSocialGraphAndMatchGraphControllers()
    }

    /**
     * Computes the bounding rects of the title, match, and buttons in the match view.
     */
    private func computeComponentRects(frameHeight: CGFloat, outerBoundingRect: CGRect, marginBetweenElements: CGFloat = 0) -> (CGRect, CGRect, CGRect) {
        let buttonSectionSize: CGSize = CGSizeMake(4, 1).resizeDimensionsToFit(outerBoundingRect.size)
        let matchSectionSize: CGSize = CGSizeMake(1, 1).resizeDimensionsToFit(outerBoundingRect.size)
        let titleSectionSize: CGSize = CGSizeMake(outerBoundingRect.width, kMatchViewTitleHeight)
        let buttonSectionRect = CGRectMake(outerBoundingRect.origin.x, frameHeight - kCouplrNavigationBarHeight - buttonSectionSize.height - marginBetweenElements, buttonSectionSize.width, buttonSectionSize.height)
        let matchSectionRect = CGRectMake(outerBoundingRect.origin.x, buttonSectionRect.origin.y - matchSectionSize.height - marginBetweenElements, matchSectionSize.width, matchSectionSize.height)
        let titleSectionRect = CGRectMake(outerBoundingRect.origin.x, matchSectionRect.origin.y - titleSectionSize.height - marginBetweenElements, titleSectionSize.width, titleSectionSize.height)
        return (buttonSectionRect.shrinkByRatio(0.01), matchSectionRect.shrinkByRatio(0.01), titleSectionRect.shrinkByRatio(0.01))
    }
    
    func initializeSocialGraphAndMatchGraphControllers() {
        if isInitializingSocialNetwork {
            return
        }
        isInitializingSocialNetwork = true
        socialGraphController.delegate = self
        // TODO Retry query upon failure.
        socialGraphController.graphInitializeBeginTime = currentTimeInSeconds()
        matchGraphController.matches = MatchGraph()
        matchGraphController.fetchMatchTitles({ (success: Bool) -> Void in
            if success {
                self.socialGraphController.initializeGraph()
                let titleList: [MatchTitle] = self.matchGraphController.matchTitles()
                if titleList.count == 0 {
                    showLoginWithAlertViewErrorMessage("Our servers are overloaded! Try again later.", "Something went wrong.")
                } else {
                    self.matchTitle.setTitle(titleList[0].text, forState: .Normal)
                    self.selectedTitle = titleList[0]
                    self.titleSelectButton.setImage(UIImage(named: titleList[0].picture), forState: .Normal)
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
    
    func namesToggled(sender: UIButton) {
        sender.selected = !sender.selected
        if sender.selected {
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
        toggleNamesButton.selected = false
    }
    
    func showAllNames() {
        for cell in collectionView!.visibleCells() as! [ProfilePictureCollectionViewCell] {
            let randomSample: [UInt64] = socialGraphController.currentSample()
            let indexPath = collectionView!.indexPathForCell(cell)!
            cell.userName = socialGraphController.nameFromId(randomSample[indexPath.row])
            cell.addTransparentLayer()
            cell.overrideLayerSelection = true
        }
    }
    
    func hideAllNames() {
        for cell in collectionView!.visibleCells() as! [ProfilePictureCollectionViewCell] {
            let randomSample: [UInt64] = socialGraphController.currentSample()
            let indexPath = collectionView!.indexPathForCell(cell)!
            cell.overrideLayerSelection = false
            if !contains(selectedIndices, indexPath) {
                cell.removeTransparentLayer()
            }
        }
    }

    func showTitleSelect() {
        let pickerView = PickerView.createPickerViewInView(UIApplication.sharedApplication().delegate!.window!!, animated: true)
        pickerView.dataSource = self
        pickerView.delegate = self
        pickerView.selectRow(selectedRow, inComponent: 0, animated: false)
        UserSessionTracker.sharedInstance.notify("opened title select")
    }

    func shuffleUnselectedMatches() {
        if socialGraphLoaded {
            var keepUsersAtIndices: [(UInt64, Int)] = []
            for (index: Int, userId: UInt64) in enumerate(selectedUsers) {
                keepUsersAtIndices.append(userId, selectedIndices[index].row)
            }
            socialGraphController.updateRandomSample(keepUsersAtIndices: keepUsersAtIndices)
            let priority = DISPATCH_QUEUE_PRIORITY_DEFAULT
            dispatch_async(dispatch_get_main_queue()) {
                let indexPaths = self.collectionView?.indexPathsForVisibleItems()
                self.collectionView?.reloadItemsAtIndexPaths(indexPaths!.filter({ (index: AnyObject) -> Bool in
                    return find(self.selectedIndices, index as! NSIndexPath) == nil
                }))
                for index in self.selectedIndices {
                    self.collectionView?.selectItemAtIndexPath(index, animated: false, scrollPosition: .None)
                }
                
                dispatch_async(dispatch_get_main_queue()) {
                    if self.toggleNamesButton.selected {
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
            for index: NSIndexPath in selectedIndices {
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
        let titleList: [MatchTitle] = matchGraphController.matchTitles()
        let randomIndex: Int = randomInt(titleList.count)
        selectedTitle = titleList[randomIndex]
        selectedRow = randomIndex
        matchTitle.setTitle(selectedTitle!.text, forState: .Normal)
        titleSelectButton.setImage(UIImage(named: selectedTitle!.picture), forState: .Normal)
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
        let titles: [MatchTitle] = matchGraphController.matchTitles()
        selectedTitle = titles[row]
        selectedRow = row
        UserSessionTracker.sharedInstance.notify("selected title id \(titles[row].id)")
        matchTitle.setTitle(selectedTitle!.text, forState: .Normal)
        titleSelectButton.setImage(UIImage(named: titles[row].picture), forState: .Normal)
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
        cell.backgroundColor = UIColor.whiteColor()
        let randomSample: [UInt64] = socialGraphController.currentSample()
        if randomSample.count > 0 {
            let userId = randomSample[indexPath.row]
            dispatch_async(dispatch_get_main_queue()) {
                cell.imageView.sd_setImageWithURL(profilePictureURLFromId(userId), placeholderImage: UIImage(named: "unknown"))
            }
        }
        return cell
    }

    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        UserSessionTracker.sharedInstance.notify("selected match \(indexPath.row)")
        if selectedUsers.count < 2 {
            let cell = collectionView.cellForItemAtIndexPath(indexPath) as! ProfilePictureCollectionViewCell
            let randomSample: [UInt64] = socialGraphController.currentSample()
            cell.userName = socialGraphController.nameFromId(randomSample[indexPath.row])
            cell.backgroundColor = kCouplrRedColor
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
        cell.backgroundColor = UIColor.whiteColor()
        let randomSample: [UInt64] = socialGraphController.currentSample()
        if let index = find(selectedUsers, randomSample[indexPath.row]) {
             selectedIndices.removeAtIndex(index)
             selectedUsers.removeAtIndex(index)
        }
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        if toggleNamesButton.selected {
            cell.addTransparentLayer()
        }
    }

}

// MARK: - SocialGraphControllerDelegate Methods

extension MatchViewController: SocialGraphControllerDelegate {

    func socialGraphControllerDidLoadSocialGraph(graph: SocialGraph) {
        socialGraphLoaded = true
        CouplrViewCoordinator.sharedInstance.dismissLoadingScreen()
        UserSessionTracker.sharedInstance.notify("initialized social graph")
        socialGraphController.updateRandomSample()
        if isViewLoaded() {
            dispatch_async(dispatch_get_main_queue()) {
                self.collectionView?.reloadData()
            }
        }
    }
}
