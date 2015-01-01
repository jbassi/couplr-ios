//
//  ProfilePictureImageView.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 12/30/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit

class ProfilePictureImageView: UIImageView {
    
    var loading: Bool = false
    var loaded: Bool = false
    var pictureData: NSMutableData = NSMutableData()
    var pictureURL: NSString?
    var connection: NSURLConnection?
    
    init(pictureURL: NSString) {
        super.init()
        self.pictureURL = pictureURL
        let request: NSURLRequest = NSURLRequest(URL: NSURL(string: pictureURL)!)
        self.connection = NSURLConnection(request: request, delegate: self)
    }
    
    func performRequestWith(URL: NSString) {
        pictureURL = URL
        let request: NSURLRequest = NSURLRequest(URL: NSURL(string: URL)!)
        connection = NSURLConnection(request: request, delegate: self)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
}

extension ProfilePictureImageView: NSURLConnectionDataDelegate {
    
    func connection(connection: NSURLConnection, didFailWithError error: NSError) {
        loading = false
    }
    
    func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
        pictureData.length = 0
    }
    
    func connection(connection: NSURLConnection, didReceiveData data: NSData) {
        pictureData.appendData(data)
    }
    
    func connectionDidFinishLoading(connection: NSURLConnection) {
        loaded = true
        loading = false
        self.image = UIImage(data: pictureData)
        pictureData.length = 0
    }
    
}