//
//  RandomLoadingMessage.swift
//  couplr-ios
//
//  Created by Wenson Hsieh on 5/26/15.
//  Copyright (c) 2015 Jeremy Bassi. All rights reserved.
//

import UIKit

func sampleRandomLoadingMessage(wave: Int) -> String {
    return kRandomLoadingMessages[wave][randomInt(kRandomLoadingMessages[wave].count)]
}

class RandomLoadingMessage {
    init() {
        waveIndex = 0
        message = sampleRandomLoadingMessage(waveIndex)
    }
    
    func next() -> String {
        waveIndex = (waveIndex + 1) % kRandomLoadingMessages.count
        message = sampleRandomLoadingMessage(waveIndex)
        return message
    }
    
    func get() -> String {
        return message
    }
    
    func reset() {
        waveIndex = 0
        message = sampleRandomLoadingMessage(waveIndex)        
    }
    
    var waveIndex: Int
    var message: String
}
