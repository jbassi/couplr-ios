//
//  PickerView.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/28/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class PickerView: UIPickerView {
    
    let transparentLayer: UIView = UIView()
    let blurView = FXBlurView()
    
    class func createPickerViewInView(view: UIView, animated: Bool) -> PickerView {
        let pickerView = PickerView(frame: view.bounds)
        pickerView.backgroundColor = UIColor.whiteColor()
        
        view.addSubview(pickerView)
        
        pickerView.showAnimated(animated)
        return pickerView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        transparentLayer.frame = frame
        transparentLayer.backgroundColor = kPickerTransparentLayerBackgroundColor
        transparentLayer.alpha = 0
        
        blurView.frame = frame
        blurView.blurEnabled = true
        blurView.tintColor = UIColor.clearColor()
        blurView.blurRadius = kPickerViewBlurViewBlurRadius
        blurView.alpha = 0
        
        let boxWidth: CGFloat = frame.width - kPickerViewWidthInsets
        let boxHeight: CGFloat = kPickerViewHeight
        
        let boxX = round((frame.size.width - boxWidth) / 2)
        let boxY = frame.size.height + boxHeight
        
        let boxRect = CGRect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)
        
        self.frame = boxRect
        self.layer.cornerRadius = kPickerViewCornerRadius
        
        var gestureRecognizer = UITapGestureRecognizer(target: self, action: Selector("handleTapGesture:"))
        gestureRecognizer.delegate = self
        blurView.addGestureRecognizer(gestureRecognizer)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Animation Functions
    
    func showAnimated(animated: Bool) {
        if animated {
            superview!.insertSubview(blurView, belowSubview: self)
            superview!.insertSubview(transparentLayer, belowSubview: blurView)
            
            UIView.animateWithDuration(kPickerShowAnimationDuration, delay: 0, usingSpringWithDamping: kPickerShowSpringDamping, initialSpringVelocity: kPickerSpringVelocity, options: UIViewAnimationOptions(0), animations: {
                self.frame.origin.y = round((self.superview!.frame.size.height - self.frame.size.height) / 2)
            }, completion: nil)
            UIView.animateWithDuration(kPickerShowAnimationDuration, animations: {
                self.transparentLayer.alpha = 1
                self.blurView.alpha = 1
            }, completion: nil)
        }
    }
    
    func hideAnimated(animated: Bool) {
        if animated {
            UIView.animateWithDuration(kPickerHideAnimationDuration, animations: {
                    self.frame.origin.y = self.superview!.frame.size.height + self.frame.size.height
                    self.transparentLayer.alpha = 0
                    self.blurView.alpha = 0
                }, completion: { (completed:Bool) in
                    self.blurView.removeFromSuperview()
                    self.transparentLayer.removeFromSuperview()
                    self.removeFromSuperview()
            })
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
