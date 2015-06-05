//
//  NewsfeedTableViewCell.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 6/4/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

class NewsfeedTableViewCell: MatchPairTableViewCell {
    
    override func layoutSubviews() {
        super.layoutSubviews()
        matchButton.frame = CGRectMake(-kMatchButtonWidth, 0, kMatchButtonWidth, frame.height)
        matchButton.backgroundColor = kCouplrGreenColor
        matchButton.setTitle("Match", forState: .Normal)
        matchButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        matchButton.addTarget(self, action: "matchButtonPressed", forControlEvents: .TouchUpInside)
        addSubview(matchButton)
    }
    
    func isButtonHidden() -> Bool {
        return buttonHidden
    }
    
    func setMatch(match: MatchTuple) {
        self.match = match
    }
    
    // HACK This is a kludgy way to make the cell detect button presses outside of the frame.
    override func pointInside(point: CGPoint, withEvent event: UIEvent?) -> Bool {
        if point.x < 0 {
            return super.pointInside(CGPointMake(point.x + kMatchButtonWidth, point.y), withEvent: event)
        }
        return super.pointInside(point, withEvent: event)
    }
    
    func setButtonVisible(visible: Bool) {
        matchButton.hidden = !visible
    }

    func shouldAllowUserToVote() -> Bool {
        if match == nil {
            return false
        }
        return MatchGraphController.sharedInstance.shouldAllowUserToVoteFromNewsfeed(match!.firstId, secondId: match!.secondId, titleId: match!.titleId)
    }

    func shake() {
        let position: CGPoint = self.center
        let path: UIBezierPath = UIBezierPath()
        path.moveToPoint(CGPointMake(position.x, position.y))
        path.addLineToPoint(CGPointMake(position.x - 20, position.y))
        path.addLineToPoint(CGPointMake(position.x + 10, position.y))
        path.addLineToPoint(CGPointMake(position.x - 5, position.y))
        path.addLineToPoint(CGPointMake(position.x + 2, position.y))
        path.addLineToPoint(CGPointMake(position.x, position.y))
        let animation: CAKeyframeAnimation = CAKeyframeAnimation()
        animation.keyPath = "position"
        animation.path = path.CGPath
        animation.duration = 0.5
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        CATransaction.begin()
        layer.addAnimation(animation, forKey: nil)
        CATransaction.commit()
    }
    
    func revealButton(immediately: Bool = false, onComplete: ((finished: Bool) -> Void)? = nil) {
        if !buttonHidden {
            onComplete?(finished: true)
            return
        }
        animateHorizontalImmediately(kMatchButtonWidth, timeInSeconds: immediately ? 0 : kMatchButtonRevealTimer, onComplete: { finished in
            self.buttonHidden = false
            onComplete?(finished: finished)
        })
    }
    
    func hideButton(immediately: Bool = false, onComplete: ((finished: Bool) -> Void)? = nil) {
        if buttonHidden {
            onComplete?(finished: true)
            return
        }
        animateHorizontalImmediately(0, timeInSeconds: immediately ? 0 : kMatchButtonRevealTimer, onComplete: { finished in
            self.buttonHidden = true
            if self.shouldShowHudView {
                self.animateHudView()
                self.shouldShowHudView = false
            }
            onComplete?(finished: finished)
        })
    }


    func matchButtonPressed() {
        if match == nil {
            return
        }
        MatchGraphController.sharedInstance.userDidMatch(match!.firstId, to: match!.secondId, withTitleId: match!.titleId)
        UserSessionTracker.sharedInstance.notify("submitted match via newsfeed")
        shouldShowHudView = true
        hideButton()
    }
    
    private func animateHudView() {
        hudView = HudView.hudInView(self, animated: true)
        hudView?.text = "Matched"
        afterDelay(0.5, { self.hudView?.hideAnimated(true) })
    }
    
    private func animateHorizontalImmediately(toOffset: CGFloat, timeInSeconds: Double, onComplete: ((finished: Bool) -> Void)? = nil) {
        if timeInSeconds == 0 {
            self.frame.origin.x = toOffset
            onComplete?(finished: true)
        }
        UIView.animateWithDuration(timeInSeconds, delay: 0.0, usingSpringWithDamping: 0.85, initialSpringVelocity: 20, options: .CurveEaseOut, animations: {
            self.frame.origin.x = toOffset
            return
        }, completion: onComplete)
    }
    
    private var hudView: HudView? = nil
    private var shouldShowHudView = false
    private var match: MatchTuple? = nil
    private var matchButton: UIButton = UIButton()
    private var buttonHidden: Bool = true
}
