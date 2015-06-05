//
//  HudView.swift
//  MyLocations
//
//  Created by Jeremy Bassi on 12/4/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class HudView: UIView {
    var text = ""
    
    class func hudInView(view: UIView, animated: Bool) -> HudView {
        let hudView = HudView(frame: view.bounds)
        hudView.opaque = false
        
        view.addSubview(hudView)
        view.userInteractionEnabled = false
        
        hudView.showAnimated(animated)
        return hudView
    }
    
    override func drawRect(rect: CGRect) {
        let boxWidth: CGFloat = 72
        let boxHeight: CGFloat = 72
        
        let boxX = round((bounds.size.width - boxWidth) / 2)
        let boxY = round((bounds.size.height - boxHeight) / 2)
        
        let boxRect = CGRect(x: boxX, y: boxY, width: boxWidth, height: boxHeight)
        
        let roundedRect = UIBezierPath(roundedRect: boxRect, cornerRadius: 10)
        UIColor(white: 0.3, alpha: 0.8).setFill()
        roundedRect.fill()
        
        if let image = UIImage(named: "checkmark") {
            let xRound = round(image.size.width / 2)
            let yRound = round(image.size.height / 2)
            
            let imagePoint = CGPoint(x: center.x - xRound, y: center.y - yRound - boxHeight / 8)
            
            image.drawAtPoint(imagePoint)
        }
        
        let attributes = [ NSFontAttributeName: UIFont.systemFontOfSize(16), NSForegroundColorAttributeName: UIColor.whiteColor()]
        let textSize = text.sizeWithAttributes(attributes)
        
        let textPoint = CGPoint(x: center.x - round(textSize.width / 2), y: center.y - round(textSize.height / 2) + boxHeight / 4)
        text.drawAtPoint(textPoint, withAttributes: attributes)
    }
    
    func showAnimated(animated: Bool) {
        if animated {
            alpha = 0
            transform = CGAffineTransformMakeScale(1.3, 1.3)
            UIView.animateWithDuration(0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5, options: UIViewAnimationOptions(0), animations: { self.alpha = 1; self.transform = CGAffineTransformIdentity }, completion: nil)
        }
    }
    
    func hideAnimated(animated: Bool) {
        if animated {
            UIView.animateWithDuration(kPickerHideAnimationDuration, animations: {
                self.alpha = 0
                }, completion: { (completed: Bool) in
                    self.superview!.userInteractionEnabled = true
                    self.removeFromSuperview()
            })
        }
    }
}
