//
//  AppDelegate.swift
//  Ayero
//
//  Created by Yahor Paulikau on 9/23/16.
//  Copyright © 2017 One Car Per Green. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import AWSCore
import AWSCognito
import AWSS3


// global variables
var facebookAccessToken: FBSDKAccessToken?
var userIdentifier: String = ""


// AWSIdentityProviderManager
class FacebookProvider: NSObject, AWSIdentityProviderManager {
    func logins() -> AWSTask<NSDictionary> {
        let facebookAccessToken = FBSDKAccessToken.current()
        if let token = facebookAccessToken?.tokenString {
            return AWSTask(result: [AWSIdentityProviderFacebook:token])
        }
        return AWSTask(error:NSError(domain: "Facebook Login", code: -1 , userInfo: ["Facebook" : "No current Facebook access token"]))
    }
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        //if let bundle = Bundle.main.bundleIdentifier {
        //    UserDefaults.standard.removePersistentDomain(forName: bundle)
        //}
        
        // Initialize Facebook SDK
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let initViewController: UIViewController

        facebookAccessToken = FBSDKAccessToken.current()
        if facebookAccessToken == nil {
        
            // Show login screen
            initViewController = storyboard.instantiateViewController(withIdentifier: "Login") as UIViewController
        
        } else {
            
            let _fbProvider = FacebookProvider()

            // Initialize the Amazon Cognito credentials provider
            let credentialProvider = AWSCognitoCredentialsProvider(
                regionType: .USWest2,
                identityPoolId: "us-west-2:0c554bfb-f2fb-4f79-943d-e6ea21a665d1",
                identityProviderManager: _fbProvider)
            
            // In case of getting erorr with cognito, try this.
            //credentialProvider.clearKeychain()
            //credentialProvider.clearCredentials()
            
            let configuration = AWSServiceConfiguration(region: .USWest2, credentialsProvider: credentialProvider)
            AWSServiceManager.default().defaultServiceConfiguration = configuration
            
            // Retrieve Amazon Cognito ID
            credentialProvider.getIdentityId().continueWith(block: { (task) -> AnyObject? in
                if (task.error != nil) {
                    print("Error: " + task.error!.localizedDescription)
                }
                else {
                    let cognitoId = task.result!
                    userIdentifier = cognitoId as String
                    print("Cognito id: \(cognitoId)")
                }
                return task
            })
            
            
            let dataset = AWSCognito.default().openOrCreateDataset("user_data")
            dataset.setString("John Doe", forKey:"Username")
            dataset.setString("10000", forKey:"HighScore")
            _ = dataset.synchronize()
            
            // Show Route screen
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            initViewController = storyboard.instantiateViewController(withIdentifier: "Root") as UIViewController

        }
        
        self.window?.rootViewController = initViewController

        return true
    }

    // FACEBOOK STUFF
    public func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        return FBSDKApplicationDelegate.sharedInstance().application(
            app,
            open: url as URL!,
            sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String,
            annotation: options[UIApplicationOpenURLOptionsKey.annotation]
        )
    }
    
    public func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        return FBSDKApplicationDelegate.sharedInstance().application(
            application,
            open: url as URL!,
            sourceApplication: sourceApplication,
            annotation: annotation)
    }
    

    
    // AWS STUFF
    func application(_ application: UIApplication, handleEventsForBackgroundURLSession identifier: String, completionHandler: @escaping () -> Void) {
        
        // Store the completion handler.
        AWSS3TransferUtility.interceptApplication(application, handleEventsForBackgroundURLSession: identifier, completionHandler: completionHandler)
    }

    
    // empty
    
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
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    

    
    /*func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool
    {
        return FBAppCall.handleOpenURL(url, sourceApplication: options["UIApplicationOpenURLOptionsSourceApplicationKey"] as! String)
    }*/
    

}

