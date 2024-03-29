//
//  AppDelegate.swift
//  couplr-ios
//
//  Created by Jeremy Bassi on 9/13/14.
//  Copyright (c) 2014 Jeremy Bassi. All rights reserved.
//

import UIKit
import Parse
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        window = UIWindow(frame: UIScreen.mainScreen().bounds)
        let loginViewController = LoginViewController()
        
        self.window?.rootViewController = loginViewController
        self.window?.makeKeyAndVisible()
        
        Parse.setApplicationId(kParseApplicationID, clientKey: kParseClientKey)
        FBLoginView.self
        FBProfilePictureView.self
        application.applicationSupportsShakeToEdit = true
        
        // PubNub chat server initialization.
        if kEnableChatFeature {
            PubNub.setConfiguration(kCouplrPubNubConfiguration)
            PubNub.setDelegate(ChatController.sharedInstance)
            PubNub.connect()
        }
        return true
    }

    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        return FBAppCall.handleOpenURL(url, sourceApplication: sourceApplication)
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
        MatchGraphController.sharedInstance.appWillHalt()
        if CouplrViewCoordinator.sharedInstance.shouldResetControllers() {
            MatchGraphController.sharedInstance.reset()
            SocialGraphController.sharedInstance.reset()
            CouplrViewCoordinator.sharedInstance.navigationController?.resetNavigation()
            CouplrViewCoordinator.sharedInstance.matchViewController?.resetToggleNamesSwitchAndSelectedMatches()
        }
        if kEnableChatFeature {
            ChatController.sharedInstance.saveUnflushedMessagesToCoreData()
            ChatController.sharedInstance.stopPollingForInvitations()
        }
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(application: UIApplication) {
        if SocialGraphController.sharedInstance.refreshRequired() {
            CouplrViewCoordinator.sharedInstance.showMatchViewLoadingScreen()
            CouplrViewCoordinator.sharedInstance.initializeMatchView()
        }
    }

    func applicationDidBecomeActive(application: UIApplication) {
        if SocialGraphController.sharedInstance.refreshRequired() {
            CouplrViewCoordinator.sharedInstance.showMatchViewLoadingScreen()
            CouplrViewCoordinator.sharedInstance.initializeMatchView()
        }
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        saveContext()
        if kEnableChatFeature {
            ChatController.sharedInstance.saveUnflushedMessagesToCoreData()
            ChatController.sharedInstance.stopPollingForInvitations()
        }
        MatchGraphController.sharedInstance.appWillHalt()
    }

    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "Foo.Testing2" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("CouplrData", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("CouplrData.sqlite")
        var error: NSError? = nil
        let failureReason = "There was an error creating or loading the application's saved data."
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            let dict = NSMutableDictionary()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "com.couplr", code: 405, userInfo: dict as [NSObject : AnyObject])
            UserSessionTracker.sharedInstance.notify("\(error), \(error!.userInfo)")
        }
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                UserSessionTracker.sharedInstance.notify("\(error), \(error!.userInfo)")
            }
        }
    }
}

