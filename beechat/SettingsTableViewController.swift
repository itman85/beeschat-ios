//
//  SettingsTableViewController.swift
//  beechat
//
//  Created by Phan Nguyen on 9/2/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import UIKit
import FBSDKLoginKit


class SettingsTableViewController: UITableViewController , UINavigationControllerDelegate, UIImagePickerControllerDelegate{

    @IBOutlet weak var HeaderView: UIView!
    @IBOutlet weak var imageUser: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    @IBOutlet weak var avatarCell: UITableViewCell!
    @IBOutlet weak var termsCell: UITableViewCell!
    @IBOutlet weak var privacyCell: UITableViewCell!
    @IBOutlet weak var logoutCell: UITableViewCell!
    
    @IBOutlet weak var avatarSwitch: UISwitch!
    
    var avatarSwitchStatus  = true
    let userDefaults = UserDefaults.standard
    var firstLoad: Bool?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        
        self.tableView.tableHeaderView = HeaderView
        
        imageUser.layer.cornerRadius = imageUser.frame.size.width / 2
        imageUser.layer.masksToBounds = true

        HeaderView.bringSubview(toFront: imageUser)
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        loadUserDefaults()
        updateUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func didClickAvatarImage(_ sender: AnyObject) {
        changePhoto()
    }
    
    
    @IBAction func avatarSwitchChange(_ switchState: UISwitch) {
        if switchState.isOn {
            avatarSwitchStatus = true
        } else {
            avatarSwitchStatus = false
            print("it off")
        }
        //save settings
        saveUserDefaults()
    }
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        if section == 0 { return 3 }
        if section == 1 { return 1 }
        return 0
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if ((indexPath.section == 0) && (indexPath.row == 0)) { return privacyCell }
        if ((indexPath.section == 0) && (indexPath.row == 1)) { return termsCell   }
        if ((indexPath.section == 0) && (indexPath.row == 2)) { return avatarCell  }
        if ((indexPath.section == 1) && (indexPath.row == 0)) { return logoutCell  }
        
        return UITableViewCell()
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        
        if section == 0 {
            return 0
        } else {
            return 25.0
        }
        
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let headerView = UIView()
        headerView.backgroundColor = UIColor.clear
        
        return headerView
    }

    //MARK: Tableview delegate functions
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.section == 1 && indexPath.row == 0 {
            showLogutView()
        }
        
    }


    //MARK:  Change photo
    
    func changePhoto() {
        
        let camera = Camera(delegate_: self)
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { (alert: UIAlertAction!) -> Void in
            camera.PresentPhotoCamera(target: self, canEdit: true)
        }
        
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (alert: UIAlertAction!) -> Void in
            camera.PresentPhotoLibrary(target: self, canEdit: true)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert: UIAlertAction!) -> Void in
            print("Cancel")
        }
        
        optionMenu.addAction(takePhoto)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
        
    }
    
    //MARK: UIImagePickerControllerDelegate functions
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let image = info[UIImagePickerControllerEditedImage] as! UIImage
        
        imageUser.image = image
        
        uploadAvatar(image: image) { (imageLink) -> Void in
            
            let properties = ["Avatar" : imageLink!]
            
            backendless?.userService.currentUser!.updateProperties(properties)
            
            backendless?.userService.update(backendless!.userService.currentUser, response: { (updatedUser: BackendlessUser?) -> Void in
                
                }, error: { (fault : Fault?) -> Void in
                    print("error: \(fault)")
            })
            
        }
        
        picker.dismiss(animated: true, completion: nil)
    }



    // MARK : user defaults
    func saveUserDefaults(){
        userDefaults.set(avatarSwitchStatus, forKey: kAVATARSTATE)
        userDefaults.synchronize()
    }
    
    func loadUserDefaults(){
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        
        if !firstLoad! {
            
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(avatarSwitchStatus, forKey: kAVATARSTATE)
            userDefaults.synchronize()
        }
        
        avatarSwitchStatus = userDefaults.bool(forKey: kAVATARSTATE)
    }
    
    //MARK:  UpdateUI
    func updateUI() {
        
        userNameLabel.text = backendless?.userService.currentUser.name
        
        avatarSwitch.setOn(avatarSwitchStatus, animated: false)
        
        let imageLink = backendless?.userService.currentUser.getProperty("Avatar")
        let imageUrl = imageLink as? String
        
        if let imageUrl = imageUrl {
            getImageFromURL(url: imageUrl, result: { (image) -> Void in
                
                self.imageUser.image = image
            })
        }
    }
    
    //MARK: Helper functions
    
    func showLogutView() {
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let logoutAction = UIAlertAction(title: "Log Out", style: .destructive) { (alert: UIAlertAction!) -> Void in
            //logout user
            self.logOut()
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert: UIAlertAction!) -> Void in
            print("cancelled")
        }
        
        
        optionMenu.addAction(logoutAction)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
    }

    func logOut(){
        
        removeDeviceIdFromUser()
        
        backendless?.userService.logout()
        
        //check if user login by fb, do fb logout
        if FBSDKAccessToken.current() != nil {
            
            let loginManager = FBSDKLoginManager()
            loginManager.logOut()
        }

        //remove device id from user in backend less devices
        PushUserResign()
        
        let loginView = storyboard!.instantiateViewController(withIdentifier: "LoginView")
        self.present(loginView, animated: true, completion: nil)
    }

   
}
