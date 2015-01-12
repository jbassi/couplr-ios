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

/* Social graph constants */
let kUnconnectedEdgeWeight:Float = -1000.0          // The weight of an unconnected "edge".
let kMaxNumStatuses:Int = 100                       // Number of statuses to query.
let kMaxNumPhotos:Int = 100                         // Number of photos to query.
let kMaxPhotoGroupSize:Int = 15                     // Max number of people considered in a photo.
let kMinGraphEdgeWeight:Float = 0.15                // The minimum edge weight threshold when cleaning the graph.
let kUserMatchVoteScore:Float = 1.0                 // Score for the user voting on title for a match.
// Like and comment scores.
let kCommentRootScore:Float = 0.5                   // Score for commenting on the root user's status.
let kCommentPrevScore:Float = 0.1                   // Score for being the next to comment on the root user's status.
let kLikeRootScore:Float = 0.2                      // Score for a like on the root user's status.
let kCommentLikeScore:Float = 0.4                   // Score for a like on someone's comment on the root user's status.
// Constants for scoring photo data.
let kMaxPairwisePhotoScore:Float = 1.5              // A base photo score for a picture containing only 2 people.
let kMinPhotoPairwiseWeight:Float = 0.05            // Only add edges from photo data with at least this weight.

let kSamplingWeightLimit:Float = 10                 // The coefficient for the sigmoid function.
let kSigmoidExponentialBase:Float = 3.5             // The exponential base for the sigmoid function.
let kRandomSampleCount:Int = 9                      // The number of people to randomly sample.

let kMaxGraphDataQueries:Int = 4                    // Max number of friends to query graph data from.
let kMinExportEdgeWeight:Float = 0.2                // Only export edges with more than this weight.
let kScaleFactorForExportingRootEdges:Float = 0.25  // Export root edges scaled by this number.
let kMutualFriendsThreshold:Int = 3                 // This many mutual friends to pull a friend over to the user's graph.

let kGenderBiasRatio:Float = 4.0                    // Make it this much more likely to land on the opposite gender.
let kWalkWeightUserMatchBoost:Float = 1.5           // The walk weight "bonus" for a node when the user selects a match.
let kWalkWeightDecayRate:Float = 0.5                // The decay rate for the walk weight bonus.
let kWalkWeightPenalty:Float = 0.5                  // Constant penalty per step to encourage choosing new nodes.

/* Parse-related constants */
let kParseApplicationID:String = "p8dTK5IiYdEKfubkxz1SqFigEuF9BRMHTlnOebNz"
let kParseClientKey:String = "3qw7fEgFDKJgCT1hPSii3JhF0NZHo1fCym3of2Wh"

/* URL request prefixes */
let kGenderizeURLPrefix:String = "http://api.genderize.io?"
let kFBGraphURLPrefix:String = "https://graph.facebook.com/"

/* Debugging outputs */
let kShowRandomWalkDebugOutput:Bool = false
let kOutputLogMessages:Bool = true

/* For managing local storage (core data) */
let kMinTimeBeforeNextGraphUpdate:Double = 345600 // In seconds. This is about 4 days.
