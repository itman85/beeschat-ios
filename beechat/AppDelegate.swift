//
//  AppDelegate.swift
//  beechat
//
//  Created by Phan Nguyen on 8/19/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import UIKit
import Firebase
import CoreLocation
import FBSDKCoreKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate,CLLocationManagerDelegate {

    var window: UIWindow?
    
    //setup plist to get location working
    //NSLocationWhenInUseUsageDescription = your text
    var locationManager: CLLocationManager?
    var coordinate: CLLocationCoordinate2D?
    
    //info for backendless
    let APP_ID = "94FFE6D2-769E-A838-FF8D-18A13120CD00"
    let SECRET_KEY = "6CF844D9-E5CF-ABF0-FFFA-C5C4965ECC00"
    let VERSION_NUM = "v1"
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        //
        FIRApp.configure()
        backendless?.initApp(APP_ID, secret: SECRET_KEY, version: VERSION_NUM)
        //FIRDatabase.database().persistenceEnabled = true
        
        //facebook setup
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        //print(NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last);
        //Register for push notification
        let types: UIUserNotificationType = [.alert, .badge, .sound]
        let settings = UIUserNotificationSettings(types: types, categories: nil)
        
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        
        //receive push notification when app not launched (closed)
        if let launchOptions = launchOptions as? [String: AnyObject] {
            if let notificationDictionary = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey] as? [NSObject : AnyObject] {
                self.application(application, didReceiveRemoteNotification: notificationDictionary)
            }
        }


        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        UserDefaults.standard.set(0, forKey: kBADGENUMBER)
        UserDefaults.standard.synchronize()

        application.applicationIconBadgeNumber = 0
        locationManagerStart()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        locationManagerStop()
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        if isSimulator{
            print("Running on Simulator")
            return
        }

        let deviceTokenString = deviceToken.hexString()//this is extension of Data
        print("deviceTokenString:\(deviceTokenString)")
        
        // Send to your server here...
        backendless?.messagingService.registerDeviceToken(deviceToken)
        //save device token66
        UserDefaults.standard.set(deviceToken, forKey: kDEVICETOKEN)
        UserDefaults.standard.set(true, forKey: kREGISTERDEVICE)
        UserDefaults.standard.synchronize()
    }
    
    /**
     receive push notification
     */
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("***Push Comming \(userInfo)")
        if application.applicationState == UIApplicationState.active {
            // app was already active
        } else {
            //push handling
            print("Push Comming when app not active")
            var badgeNumber = UserDefaults.standard.integer(forKey: kBADGENUMBER)
            badgeNumber += 1
            application.applicationIconBadgeNumber = badgeNumber
            
            UserDefaults.standard.set(badgeNumber, forKey: kBADGENUMBER)
            UserDefaults.standard.synchronize()
            
        }
    }
    
   /* func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject], fetchCompletionHandler completionHandler: (UIBackgroundFetchResult) -> Void) {
        print("Push Comming \(userInfo)")
        if application.applicationState == UIApplicationState.active {
            // app was already active
            print("Push Comming when app active")
        } else {
            //push handling
            print("Push Comming when app not active")
            application.applicationIconBadgeNumber = 2
            
        }

    }*/
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("couldnt register for notifications : \(error.localizedDescription)")
    }
    //MARK:  LocationManger fuctions
    
    func locationManagerStart() {
        
        if locationManager == nil {
            print("init locationManager")
            locationManager = CLLocationManager()
            locationManager!.delegate = self
            locationManager!.desiredAccuracy = kCLLocationAccuracyBest
            locationManager!.requestWhenInUseAuthorization()
        }
        
        print("have location manager")
        locationManager!.startUpdatingLocation()
    }
    
    func locationManagerStop() {
        locationManager!.stopUpdatingLocation()
    }
    
    
    //MARK: CLLocationManager Delegate
    
    /*private func locationManager(manager: CLLocationManager, didUpdateToLocation newLocation: CLLocation, fromLocation oldLocation: CLLocation) {
        
        coordinate = newLocation.coordinate
    }*/
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !(locations ?? []).isEmpty{
             //print("have location update \(locations.count)")
            coordinate = locations[0].coordinate
        }else{
            print("No location update")
        }
    }

    //MARK facebook login
    /*func application(_ app: UIApplication, open url: URL, options: [String : AnyObject] = [:]) -> Bool {
        FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options, annotation: <#T##AnyObject!#>)
    }*/
    
    //this deprecated
    //this function for open app from deep link
    //http://blog.originate.com/blog/2014/04/22/deeplinking-in-ios/
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        let result =  FBSDKApplicationDelegate.sharedInstance().application(application, open: url, sourceApplication: sourceApplication, annotation: annotation)
        /*print("FB prepare get token and send to graph")
        if result {
            
            let token = FBSDKAccessToken.current()
            
            let request = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"email"], tokenString: token?.tokenString, version: nil, httpMethod: "GET")
            request?.start(completionHandler: { (connection, result: AnyObject?, error:Error?) ->Void in
                if error == nil {
                    
                    let facebookId = result?["id"]! as! String
                    
                    print("Facebook login response ok facebookId = \(facebookId)")
                    
                    let avatarUrl = "https://graph.facebook.com/\(facebookId)/picture?type=normal"
                    
                    //update backendless user with avatar link
                    updateBackendlessUser(facebookId: facebookId, avatarUrl: avatarUrl)
                    
                } else {
                    print("Facebook request error \(error)")
                }

            })
            
            let fieldsMapping = ["id" : "facebookId", "name" : "name", "email" : "email"]
            
             print("Login Backendless with Fb user")
            backendless?.userService.login(withFacebookSDK: token, fieldsMapping: fieldsMapping)
        }*/
        
        return result

        
    }
}

