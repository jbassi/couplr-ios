//
//  PickerView.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/28/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import Foundation

class PickerView: UIPickerView {
    
    let transparentLayer: UIView = UIView()
    
    class func createPickerViewInView(view: UIView, animated: Bool) -> PickerView {
        let pickerView = PickerView(frame: view.bounds)
        pickerView.backgroundColor = UIColor.whiteColor()
        
        view.addSubview(pickerView)
        
        pickerView.showAnimated(animated)
        return pickerView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        transparentLayer.frame = UIScreen.mainScreen().bounds
        
        let boxWidth: CGFloat = frame.width - kPickerViewWidthInsets
        let boxHeight: CGFloat = kPickerViewHeight
        
        let boxX = round((frame.size.width - boxWidth) / 2)
        let boxY = frame.size.height + boxHeight
        
        let boxRect = CGRect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)
        
        self.frame = boxRect
        self.layer.cornerRadius = kPickerViewCornerRadius
        
        var gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleTapGesture:"))
        gestureRecognizer.delegate = self
        transparentLayer.addGestureRecognizer(gestureRecognizer)
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Animation Functions
    
    func showAnimated(animated: Bool) {
        if animated {
            superview!.insertSubview(transparentLayer, belowSubview: self)
            
            UIView.animateWithDuration(kPickerShowAnimationDuration, delay: 0, usingSpringWithDamping: kPickerShowSpringDamping, initialSpringVelocity: kPickerSpringVelocity, options: UIViewAnimationOptions(0), animations: {
                self.frame.origin.y = round((self.superview!.frame.size.height - self.frame.size.height) / 2)
                self.transparentLayer.backgroundColor = kPickerTransparentLayerShowColor
                }, completion: nil)
        }
    }
    
    func hideAnimated(animated: Bool) {
        if animated {
            UIView.animateWithDuration(kPickerHideAnimationDuration, delay: 0, usingSpringWithDamping: kPickerHideSpringDamping, initialSpringVelocity: kPickerSpringVelocity, options: UIViewAnimationOptions(0), animations: {
                self.frame.origin.y = self.superview!.frame.size.height + self.frame.size.height
                self.transparentLayer.backgroundColor = kPickerTransparentLayerHideColor
                }, completion: nil)
            
            transparentLayer.removeFromSuperview()
        }
    }
    
    // MARK: - handleTapGesture
    
    func handleTapGesture(gesture: UITapGestureRecognizer) {
        hideAnimated(true)
    }
    
}

// MARK: - UIGestureRecognizerDelegate Methods

extension PickerView: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        return true
    }
    
}