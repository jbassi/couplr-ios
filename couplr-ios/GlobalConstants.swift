//
//  GlobalConstants.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/28/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

/* iOS Navigation Bar Height */
let kStatusBarSize = UIApplication.sharedApplication().statusBarFrame.size
let kStatusBarHeight = min(kStatusBarSize.width, kStatusBarSize.height)

/* CouplrSettingsManager Constants */
let kShouldSkipLoginKey: String = "kShouldSkipLoginKey"

/* CouplrNavigationController Constants */
let kMatchViewButtonTag = 1000
let kProfileViewButtonTag = 1001
let kMatchViewButtonTitle = "Matches"
let kProfileViewButtonTitle = "Profile"
let kCouplrNavigationBarHeight: CGFloat = 50.0
let kCouplrNavigationBarButtonHeight: CGFloat = 50.0
let kCouplrNavigationBarSelectionIndicatorHeight: CGFloat = 7.0

/* Storyboard View Names */
let kStoryboardName = "Main"
let kStoryboardMatchViewControllerName = "MatchViewController"
let kStoryboardProfileViewControllerName = "ProfileViewController"

/* Facebook API */
let kMaxAllowedBatchRequestSize:Int = 50

/* PickerView Constants */
let kPickerViewWidthInsets: CGFloat = 80.0
let kPickerViewHeight: CGFloat = 180.0
let kPickerViewCornerRadius: CGFloat = 3.0
let kPickerShowAnimationDuration: NSTimeInterval = 0.6
let kPickerHideAnimationDuration: NSTimeInterval = 0.5
let kPickerShowSpringDamping: CGFloat = 0.7
let kPickerHideSpringDamping: CGFloat = 0.5
let kPickerSpringVelocity: CGFloat = 0.5

/* ProfilePictureCollectionViewCell Constants */
let kProfilePictureCollectionViewCellHideAnimationDuration = 0.2

/* ProfileViewControllerTableViewCell Constants */
let kProfileViewControllerTableViewCellPadding: CGFloat = 10.0
let kProfileViewControllerTableViewCellWidth: CGFloat = 40.0

/* ProfileViewController Constants */
let kProfileViewControllerMaximumNumberOfMatches = 99
let kProfileViewControllerMaximumNumberOfMatchesString = "99+"
let kProfileViewControllerDetailViewHeight: CGFloat = 150

/* ProfileDetailView Constants */
let kProfileDetailViewProfilePictureRatio: CGFloat = 0.70
let kProfileDetailViewProfilePicturePadding: CGFloat = 4
let kProfileDetailViewProfilePictureXRatio: CGFloat = 0.075
let kProfileDetailViewProfilePictureYRatio: CGFloat = 0.20
let kProfileDetailViewBottomBorderWidth: CGFloat = 10
let kProfileDetailViewBottomBorderHeight: CGFloat = 1
let kProfileDetailViewNameLabelX: CGFloat = 32

/* ProfileDetailView Fonts */
let kProfileDetailViewProfileNameLabelFont = UIFont(name: "HelveticaNeue-Light", size: 26)

/* MatchViewControllerCollectionView Constants */
let kMatchViewControllerCollectionViewNumberOfRows: Int = 9

/* PickerView Colors */
let kPickerTransparentLayerShowColor: UIColor = UIColor(white: 0.1, alpha: 0.8)
let kPickerTransparentLayerHideColor: UIColor = UIColor(white: 1, alpha: 0)

/* Social graph constants */
let kUnconnectedEdgeWeight:Float = -1000.0
// Like and comment scores
let kCommentRootScore:Float = 0.8
let kCommentPrevScore:Float = 0.1
let kLikeRootScore:Float = 0.2
let kCommentLikeScore:Float = 0.4
let kSamplingWeightLimit:Float = 10
let kRandomSampleCount:Int = 9
let kMaxGraphDataQueries:Int = 4
let kSigmoidExponentialBase:Float = 3.5
let kScaleFactorForExportingRootEdges:Float = 0.2
// Make it this much more likely to land on someone of the opposite gender.
let kGenderBiasRatio:Float = 6.0
// Constants for multipliers determining walk weight bonuses for nodes the user selects.
let kWalkWeightMultiplierBoost:Float = 1.0
let kWalkWeightMultiplierDecayRate:Float = 0.5

/* Parse configuration */
let kParseApplicationID:String = "p8dTK5IiYdEKfubkxz1SqFigEuF9BRMHTlnOebNz"
let kParseClientKey:String = "3qw7fEgFDKJgCT1hPSii3JhF0NZHo1fCym3of2Wh"

/* URL request prefixes */
let kGenderizeURLPrefix:String = "http://api.genderize.io?"
let kFBGraphURLPrefix:String = "https://graph.facebook.com/"

/* Debugging outputs */
let kShowRandomWalkDebugOutput:Bool = false
let kOutputLogMessages:Bool = true
