//
//  RegisterViewController.swift
//  beechat
//
//  Created by Phan Nguyen on 8/25/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import UIKit
import ProgressHUD
class RegisterViewController: UIViewController ,UINavigationControllerDelegate, UIImagePickerControllerDelegate{
    
    
    @IBOutlet weak var avatarImageView: UIImageView!
    
    @IBOutlet weak var emailTextField: UITextField!
    
    @IBOutlet weak var usernameTextField: UITextField!

    @IBOutlet weak var passwordTextField: UITextField!
    
    let backendless = Backendless.sharedInstance()
    
    var email:String?
    var username:String?
    var password:String?
    var avatarImage:UIImage?
    var newUser:BackendlessUser?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        newUser = BackendlessUser()
        
        //Looks for single or multiple taps.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: "dismissKeyboard")
        view.addGestureRecognizer(tap)
        
    }

    //Calls this function when the tap is recognized to hide keyboard
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
    /*
     This extension will help to dismiss keyboard when touch anywhere in view
    extension UIViewController {
        func hideKeyboardWhenTappedAround() {
            let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
            view.addGestureRecognizer(tap)
        }
        
        func dismissKeyboard() {
            view.endEditing(true)
        }
    }
     
     Now in every UIViewController, all you have to do is call this function:
     
     override func viewDidLoad() {
        super.viewDidLoad()
        self.hideKeyboardWhenTappedAround()
     }
    */
    
    
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
    
    
    @IBAction func registerButtonPress(_ sender: UIButton) {
        if emailTextField.text != "" && usernameTextField.text != "" && passwordTextField.text != ""{
            ProgressHUD.show("Registering...")
            email = emailTextField.text
            username = usernameTextField.text
            password = passwordTextField.text
            
            registerBackendlessUser(email: email!, username: username!, password: password!, avatarImage: avatarImage)
            
        }else{
            //show alert
            ProgressHUD.showError("All fields are required")
        }
    }
    
    
    
    @IBAction func cameraBarItemPressed(_ sender: AnyObject) {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        let camera = Camera(delegate_: self)
        
        
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { (alert: UIAlertAction!) -> Void in
            camera.PresentPhotoCamera(target: self, canEdit: true)
        }
        
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (alert : UIAlertAction!) -> Void in
            camera.PresentPhotoLibrary(target: self, canEdit: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (aler : UIAlertAction!) -> Void in
            print("Cancelled")
        }
        
        
        optionMenu.addAction(takePhoto)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    //MARK: UIImagepickercontroller delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        self.avatarImage = (info[UIImagePickerControllerEditedImage] as! UIImage)
        
        avatarImageView.image = avatarImage
        
        picker.dismiss(animated: true, completion: nil)
    }

    
    //backend less user registration
    func registerBackendlessUser(email:String,username:String,password:String,avatarImage:UIImage?){
        newUser!.email = email
        newUser!.name = username
        newUser!.password = password
        
        UIApplication.shared.registerForRemoteNotifications()
        
        if avatarImage == nil {
            newUser!.setProperty("Avatar", object: "")
        } else {
            
            uploadAvatar(image: avatarImage!, result: { (imageLink) -> Void in
                
                let properties = ["Avatar" : imageLink!]
                
                self.backendless?.userService.currentUser!.updateProperties(properties)
                
                self.backendless?.userService.update(self.backendless!.userService.currentUser, response: { (updatedUser: BackendlessUser?) -> Void in
                    print("Updated current user avatar")
                    }, error: { (fault : Fault?) -> Void in
                        print("Error couldnt set avatar image \(fault)")
                })
            })
        }

        
        //backendless?.userService.registering(newUser,response : { (registeredUser:BackendlessUser!) -> Void in})
        backendless?.userService.registering(newUser!, response: { (registeredUser: BackendlessUser?) -> Void in
            ProgressHUD.dismiss()
            //register new user success
            self.loginUser(email: email, username: username, password: password)
            self.emailTextField.text = ""
            self.usernameTextField.text = ""
            self.passwordTextField.text = ""
            }) { (fault:Fault?) -> Void in
                print("Server response error, cannot register new user: \(fault)")
                ProgressHUD.dismiss()
        }
    }
    
    func loginUser(email:String,username:String,password:String){
        backendless?.userService.login(email, password: password, response: { (loginUser:BackendlessUser?) in
            
            registerUserDeviceId()
            
            //here seque to recent message
            let viewcontroller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ChatVC") as! UITabBarController
            viewcontroller.selectedIndex = 0
            self.present(viewcontroller, animated: true, completion: nil)
            
            }, error: { (fault:Fault?) in
                print("Server response error, login failed \(fault)")
                ProgressHUD.dismiss()
        })
    }

}
