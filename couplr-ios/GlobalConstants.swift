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
let kProfileViewButtonTag = 0
let kMatchViewButtonTag = 1
let kNewsfeedViewButtonTag = 2
let kHistoryViewButtonTag = 3
let kMatchViewButtonTitle = "Matches"
let kProfileViewButtonTitle = "Profile"
let kNewsfeedViewButtonTitle = "News"
let kHistoryViewButtonTitle = "History"
let kCouplrNavigationButtonFont: UIFont = UIFont.systemFontOfSize(18.0)
let kCouplrNavigationButtonBoldFont: UIFont = UIFont.boldSystemFontOfSize(18.0)
let kCouplrNavigationBarHeight: CGFloat = 50.0
let kCouplrNavigationBarButtonHeight: CGFloat = 50.0
let kCouplrNavigationBarSelectionIndicatorHeight: CGFloat = 4.0
let kCouplrNavigationBarSelectionIndicatorCornerRadius: CGFloat = 2.5

/* Couplr Default Color */
let kCouplrRedColor = UIColor(red: 246/255.0, green: 71/255.0, blue: 71/255.0, alpha: 1)

/* Empty TableView Strings */
let kEmptyTableViewMessage = "It looks like cupid is on hiatus. Please check back later!"

/* Facebook API */
let kMaxAllowedBatchRequestSize:Int = 50
let kFacebookAPIVersion:String = "v2.2"

/* General TableViewCell Constatns */
let kTableViewCellHeight: CGFloat = 80

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
let kLoadingViewShowAnimationDuration: NSTimeInterval = 0.3
let kLoadingViewHideAnimationDuration: NSTimeInterval = 0.2
let kLoadingLabelShowAnimationDuration: NSTimeInterval = 0.5
let kLoadingLabelHideAnimationDuration: NSTimeInterval = 0.1
let kMinLoadingDelay: Double = 0.75

/* ProfilePictureCollectionViewCell Constants */
let kProfilePictureCollectionViewCellHideAnimationDuration = 0.2

/* ImageTableViewCell Constants */
let kImageTableViewCellPadding: CGFloat = 10.0
let kImageTableViewCellWidth: CGFloat = 40.0

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
let kGenderizeURLPrefix:String = "http://couplr.herokuapp.com/gender?secret=FFE8382A3E3B4A1282CE59CAE7910BF7&names="
let kFBGraphURLPrefix:String = "https://graph.facebook.com/"

/* For managing local storage (core data) */
let kSecondsBeforeNextGraphUpdate:Double = 345600 // In seconds. This is about 4 days.
let kEnableGraphCaching:Bool = true

/* Recent match view */
let kMinNumRecentMatches:Int = 10

/* Graph paths for posts and photos. */
let kPostGraphPathFields:String = "fields=from,likes,comments.fields(from,likes)"
let kPhotosGraphPathFields:String = "fields=from,tags.fields(id,name)"

/* News feed */
let kMaxNumNewsFeedMatches:Int = 25
let kMaxNumClosestFriends:Int = 25

/* Debugging output */
let kOutputLogMessages:Bool = false