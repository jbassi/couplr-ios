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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        matchTitleLabel.setTitle(testData[0], forState: UIControlState.Normal)
//        testFriendList()
        testGETRequest()
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