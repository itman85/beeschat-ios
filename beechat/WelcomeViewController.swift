//
//  WelcomeViewController.swift
//  beechat
//
//  Created by Phan Nguyen on 8/25/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit

class WelcomeViewController: UIViewController, FBSDKLoginButtonDelegate {
   
   

    
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    
    override func viewWillAppear(_ animated: Bool) {
        backendless?.userService.setStayLoggedIn(true)
       
        if backendless?.userService.currentUser != nil{
            DispatchQueue.main.async {
                let viewcontroller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatVC") as! UITabBarController
                viewcontroller.selectedIndex = 0
                self.present(viewcontroller, animated: true, completion: nil)
            }
            
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        fbLoginButton.readPermissions = ["public_profile","email"]
        fbLoginButton.delegate = self
        fbLoginButton.loginBehavior = FBSDKLoginBehavior.browser
        
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    //FB login button press delegate
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        if ((error) != nil) {
            // Process error
            print("Login fb button press error")
        }
        else if result.isCancelled {
            // Handle cancellations
            print("Login fb button press Cancel")
        }
        else {
            // Navigate to other view
            print("Login fb button press OK")
            shouldRegisterDeviceAgain()
            fetchFBUserInfo()
            if backendless?.userService.currentUser != nil{
                print("Move to Chat view")
                DispatchQueue.main.async {
                    let viewcontroller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatVC") as! UITabBarController
                    viewcontroller.selectedIndex = 0
                    self.present(viewcontroller, animated: true, completion: nil)
                }
            }

        }
    }
    
    //FB logout button press delegate
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        print("Logout fb Button press")
    }
    
    func fetchFBUserInfo(){
         print("Fetch fb info")
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
    }

}
