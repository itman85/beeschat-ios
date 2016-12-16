//
//  LoginViewController.swift
//  beechat
//
//  Created by Phan Nguyen on 8/25/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import UIKit
import ProgressHUD
class LoginViewController: UIViewController {
  
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var passwordTextField: UITextField!
    
    let backendless = Backendless.sharedInstance()
    var email:String?    
    var password:String?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
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
    

    @IBAction func loginBarButtonItemPress(_ sender: UIBarButtonItem) {
        if emailTextField.text != "" && passwordTextField.text != "" {
            ProgressHUD.show("Login...")
            email = emailTextField.text
            password = passwordTextField.text
            //login to backend less
            loginUser(email:email!,password:password!)
            
            UIApplication.shared.registerForRemoteNotifications()
            
        }else{
            //show alert
            ProgressHUD.showError("All fields are required")
        }

    }
    
    func loginUser(email:String,password:String){
        if backendless != nil{
            backendless!.userService.login(email, password: password, response: { (loginUser:BackendlessUser?) in
                //login success
                ProgressHUD.dismiss()
                self.emailTextField.text = ""
                self.passwordTextField.text = ""
                
                //update device id to backend less
                registerUserDeviceId()
                
                //segue to recents view
                print("logged in")
                let viewcontroller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatVC") as! UITabBarController
                viewcontroller.selectedIndex = 0
                self.present(viewcontroller, animated: true, completion: nil)
                }, error: { (fault:Fault?) in
                    print("Server response error, login failed \(fault)")
                    ProgressHUD.dismiss()
            })
        }else{
            print("Cannot connect to backendless")
            ProgressHUD.dismiss()
        }
    }
}
