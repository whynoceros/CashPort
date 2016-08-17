//
//  AppDelegate.swift
//  CashPort
//
//  Created by Gabriel Nadel on 8/9/16.
//  Copyright © 2016 Treehouse. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func applicationWillTerminate(application: UIApplication) {
        
        //To save changes, utilize DataController
        //In current state, only a single favorite persists and that is saved with each new set. No need to explicitly save on app termination.
        
    }

   }

