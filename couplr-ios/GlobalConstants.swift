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
let kCouplrNavigationButtonFont: UIFont = UIFont.systemFontOfSize(18.0)
let kCouplrNavigationButtonBoldFont: UIFont = UIFont.boldSystemFontOfSize(18.0)
let kCouplrNavigationBarHeight: CGFloat = 50.0
let kCouplrNavigationBarButtonHeight: CGFloat = 50.0
let kCouplrNavigationBarSelectionIndicatorHeight: CGFloat = 4.0
let kCouplrNavigationBarSelectionIndicatorCornerRadius: CGFloat = 2.5

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
let kPickerViewBlurViewBlurRadius: CGFloat = 20.0
let kPickerShowAnimationDuration: NSTimeInterval = 0.5
let kPickerHideAnimationDuration: NSTimeInterval = 0.4
let kPickerShowSpringDamping: CGFloat = 0.7
let kPickerHideSpringDamping: CGFloat = 0.5
let kPickerSpringVelocity: CGFloat = 0.5

/* LoadingView Constants */
let kLoadingViewBlurViewBlurRadius: CGFloat = 20.0
let kLoadingViewShowAnimationDuration: NSTimeInterval = 0.5
let kLoadingViewHideAnimationDuration: NSTimeInterval = 0.4
let kLoadingLabelShowAnimationDuration: NSTimeInterval = 1.0
let kLoadingLabelHideAnimationDuration: NSTimeInterval = 0.1

/* ProfilePictureCollectionViewCell Constants */
let kProfilePictureCollectionViewCellHideAnimationDuration = 0.2

/* ProfileViewControllerTableViewCell Constants */
let kProfileViewControllerTableViewCellPadding: CGFloat = 10.0
let kProfileViewControllerTableViewCellWidth: CGFloat = 40.0

/* ProfileViewController Constants */
let kProfileViewControllerMaximumNumberOfMatches = 99
let kProfileViewControllerMaximumNumberOfMatchesString = "99+"
let kProfileViewControllerDetailViewHeight: CGFloat = 150
let kMaxNameDisplayLength:Int = 25

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
let kPickerTransparentLayerBackgroundColor: UIColor = UIColor(white: 0.1, alpha: 0.6)

/* LoadingView Colors */
let kLoadingViewTransparentLayerBackgroundColor: UIColor = UIColor(white: 0.1, alpha: 0.7)

/* Parse-related constants */
let kParseApplicationID:String = "p8dTK5IiYdEKfubkxz1SqFigEuF9BRMHTlnOebNz"
let kParseClientKey:String = "3qw7fEgFDKJgCT1hPSii3JhF0NZHo1fCym3of2Wh"

/* URL request prefixes */
let kGenderizeURLPrefix:String = "http://gender-ml.herokuapp.com/classify?auth_token=FFE8382A3E3B4A1282CE59CAE7910BF7&names="
let kFBGraphURLPrefix:String = "https://graph.facebook.com/"

/* For managing local storage (core data) */
let kSecondsBeforeNextGraphUpdate:Double = 345600 // In seconds. This is about 4 days.
let kEnableGraphCaching:Bool = true

/* Graph paths for statuses and photos. */
let kStatusGraphPathFields:String = "fields=from,likes,comments.fields(from,likes)"
let kPhotosGraphPathFields:String = "fields=from,tags.fields(id,name)"

/* Debugging outputs */
let kShowRandomWalkDebugOutput:Bool = false
let kOutputLogMessages:Bool = true