//
//  CouplrLoadingView.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 1/7/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class LoadingView: UIView {

    let transparentLayer: UIView = UIView()
    let loadingLabel = UILabel()
    let blurView = FXBlurView()
    
    class func createLoadingScreenInView(view: UIView, animated: Bool) -> LoadingView {
        let loadingView = LoadingView(frame: view.bounds)
        
        view.addSubview(loadingView)
        
        loadingView.showAnimated(animated)
        return loadingView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadingLabel.frame = self.frame
        loadingLabel.text = "Loading..."
        loadingLabel.alpha = 0
        loadingLabel.textColor = UIColor.whiteColor()
        loadingLabel.textAlignment = NSTextAlignment.Center
        
        transparentLayer.frame = frame
        transparentLayer.backgroundColor = kLoadingViewTransparentLayerBackgroundColor
        transparentLayer.alpha = 0
        
        blurView.frame = frame
        blurView.blurEnabled = true
        blurView.tintColor = UIColor.clearColor()
        blurView.blurRadius = kLoadingViewBlurViewBlurRadius
        blurView.alpha = 0
        
        self.addSubview(loadingLabel)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Animation Functions
    
    func showAnimated(animated: Bool) {
        if animated {
            superview!.insertSubview(blurView, belowSubview: self)
            superview!.insertSubview(transparentLayer, belowSubview: blurView)
            
            UIView.animateWithDuration(kLoadingViewShowAnimationDuration, animations: {
                self.transparentLayer.alpha = 1
                self.blurView.alpha = 1
                }, completion: { (completed:Bool) in
                    if completed {
                        UIView.animateWithDuration(kLoadingLabelShowAnimationDuration, animations: { self.loadingLabel.alpha = 1 })
                    }
            })
        }
    }
    
    func hideAnimated(animated: Bool) {
        if animated {
            UIView.animateWithDuration(kLoadingLabelHideAnimationDuration, animations: { self.loadingLabel.alpha = 0 })
            UIView.animateWithDuration(kLoadingViewHideAnimationDuration, animations: {
                self.transparentLayer.alpha = 0
                self.blurView.alpha = 0
                }, completion: { (completed:Bool) in
                    self.blurView.removeFromSuperview()
                    self.transparentLayer.removeFromSuperview()
                    self.loadingLabel.removeFromSuperview()
                    self.removeFromSuperview()
            })
        }
    }

}
