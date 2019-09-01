//
//  LoginViewController.swift
//  Ayero
//
//  Created by Yahor Paulikau on 6/20/17.
//  Copyright © 2017 One Car Per Green. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin
import FBSDKCoreKit
//import FBSDKShareKit
import FBSDKLoginKit


var fbLoginSuccess = false


class LoginViewController: UIViewController, FBSDKLoginButtonDelegate {
 
    @IBOutlet weak var btnLoginFacebook: FBSDKLoginButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        btnLoginFacebook.delegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureFacebook()
    {
        btnLoginFacebook.readPermissions = ["public_profile", "email", "picture", "name", "gender", "age_range"];
        btnLoginFacebook.delegate = self
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if error == nil {
            print("Success")
            
            let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"gender,email,age_range,name,picture.width(480).height(480)"])
            graphRequest.start(completionHandler: { (connection, result, error) -> Void in
                
                if ((error) != nil)
                {
                    print("Error: \(String(describing: error))")
                }
                else
                {
                    print("fetched user: \(String(describing: result))")                    
                }
            })
            
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc: UIViewController = storyboard.instantiateViewController(withIdentifier: "Root") as UIViewController
            
            self.present(vc, animated: true, completion: nil)

        } else {
            print("Failure")
        }
    }
    
    /*func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        if ((error) != nil)
        {
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            fbLoginSuccess = true
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
            }
            
         }
    }*/
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {

    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
