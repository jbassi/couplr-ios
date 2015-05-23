//
//  CouplrLoadingView.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 1/7/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class LoadingView: UIView {
    
    var mask: CALayer?
    let imageLayer: UIView = UIView()
    let backgroundView: UIView = UIView()
    let loadingLabel = UILabel()
    
    class func createLoadingScreenInView(view: UIView, animated: Bool) -> LoadingView {
        let loadingView = LoadingView(frame: view.bounds)
        
        view.addSubview(loadingView)
        
        loadingView.showAnimated(animated)
        return loadingView
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        loadingLabel.frame = CGRectMake(0, self.frame.height-80, self.frame.width, 40)
        loadingLabel.text = "Loading..."
        loadingLabel.alpha = 0
        loadingLabel.textColor = UIColor.whiteColor()
        loadingLabel.textAlignment = NSTextAlignment.Center
        loadingLabel.font = UIFont(name: "HelveticaNeue-Light", size: 24)
        
        imageLayer.frame = frame
        imageLayer.backgroundColor = UIColor.whiteColor()
        
        self.mask = CALayer()
        self.mask!.contents = UIImage(named: "twitter_logo")!.CGImage
        self.mask!.contentsGravity = kCAGravityResizeAspect
        self.mask!.bounds = CGRect(x: 0, y: 0, width: 100, height: 100)
        self.mask!.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.mask!.position = CGPoint(x: imageLayer.frame.size.width/2, y: imageLayer.frame.size.height/2)
        imageLayer.layer.mask = mask
        
        backgroundView.frame = frame
        backgroundView.backgroundColor = UIColor(red: 246/255.0, green: 71/255.0, blue: 71/255.0, alpha: 1)
        backgroundView.alpha = 0
        
        backgroundView.addSubview(imageLayer)
        backgroundView.addSubview(loadingLabel)
    }

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - Animation Functions
    
    func showAnimated(animated: Bool) {
        if animated {
            self.addSubview(backgroundView)
            
            UIView.animateWithDuration(kLoadingViewShowAnimationDuration, animations: {
                self.backgroundView.alpha = 1
                }, completion: { (completed:Bool) in
                    if completed {
                        UIView.animateWithDuration(kLoadingLabelShowAnimationDuration, animations: { self.loadingLabel.alpha = 1 })
                    }
            })
        }
    }
    
    func hideAnimated() {
        let keyFrameAnimation = CAKeyframeAnimation(keyPath: "bounds")
        keyFrameAnimation.delegate = self
        keyFrameAnimation.duration = 0.8
        keyFrameAnimation.beginTime = CACurrentMediaTime() + 1 // Add delay of 1 second
        let initalBounds = NSValue(CGRect: mask!.bounds)
        let secondBounds = NSValue(CGRect: CGRect(x: 0, y: 0, width: 90, height: 90))
        let finalBounds = NSValue(CGRect: CGRect(x: 0, y: 0, width: 2500, height: 2500))
        keyFrameAnimation.values = [initalBounds, secondBounds, finalBounds]
        keyFrameAnimation.keyTimes = [0, 0.3, 1]
        keyFrameAnimation.timingFunctions = [CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut), CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseOut)]
        keyFrameAnimation.fillMode = kCAFillModeForwards
        keyFrameAnimation.removedOnCompletion = false
        
        self.mask!.addAnimation(keyFrameAnimation, forKey: "bounds")
    }
    
    override func animationDidStart(anim: CAAnimation!) {
        UIView.animateWithDuration(kLoadingLabelHideAnimationDuration, animations: { self.loadingLabel.alpha = 0 })
    }
    
    override func animationDidStop(anim: CAAnimation!, finished flag: Bool) {
        UIView.animateWithDuration(kLoadingViewHideAnimationDuration, animations: {
            self.backgroundView.alpha = 0
            }, completion: { (completed:Bool) in
                self.backgroundView.removeFromSuperview()
                self.removeFromSuperview()
        })
    }

    
}
