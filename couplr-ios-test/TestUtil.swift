//
//  TestUtil.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 5/26/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit
import XCTest

func expectDatesToMatch(date: NSDate, other: NSDate, message: String) {
    XCTAssertEqualWithAccuracy(date.timeIntervalSince1970, other.timeIntervalSince1970, 1, message)
}
