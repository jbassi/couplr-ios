//
//  GlobalConstants.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/28/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

/* CouplrSettingsManager Constants */
let kShouldSkipLoginKey: String = "kShouldSkipLoginKey"

/* PickerView Constants */
let kPickerViewWidthInsets: CGFloat = 80.0
let kPickerViewHeight: CGFloat = 180.0
let kPickerViewCornerRadius: CGFloat = 3.0
let kPickerShowAnimationDuration: NSTimeInterval = 0.6
let kPickerHideAnimationDuration: NSTimeInterval = 0.7
let kPickerShowSpringDamping: CGFloat = 0.7
let kPickerHideSpringDamping: CGFloat = 0.5
let kPickerSpringVelocity: CGFloat = 0.5

/* ProfilePictureCollectionViewCell Constants */
let kProfilePictureCollectionViewCellHideAnimationDuration = 0.2

/* MatchViewControllerCollectionView Constants */
let kMatchViewControllerCollectionViewNumberOfRows: Int = 9

/* PickerView Colors */
let kPickerTransparentLayerShowColor: UIColor = UIColor(white: 0.1, alpha: 0.8)
let kPickerTransparentLayerHideColor: UIColor = UIColor(white: 1, alpha: 0)

/* Social graph constants */
let kUnconnectedEdgeWeight:Float = -1000.0
let kCommentRootScore:Float = 0.8
let kCommentPrevScore:Float = 0.1
let kLikeRootScore:Float = 0.2
let kCommentLikeScore:Float = 0.4
let kSamplingWeightLimit:Float = 5
let kRandomSampleCount:Int = 9
let kGenderBiasCoefficient:Float = 5
let kShowRandomWalkDebugOutput:Bool = false

/* URL request prefixes */
let kGenderResolverPrefix:String = "http://api.genderize.io?"
let kFBGraphURLPrefix:String = "https://graph.facebook.com/"
