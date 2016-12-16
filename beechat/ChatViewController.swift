//
//  ChatViewController.swift
//  beechat
//
//  Created by Phan Nguyen on 8/30/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import IDMPhotoBrowser

class ChatViewController: JSQMessagesViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate  {

    let userDefaults = UserDefaults.standard
    let appDelegate = UIApplication.shared.delegate as! AppDelegate
    let ref = firebase.child("Message")
    
    var messages: [JSQMessage] = []
    var objects: [NSDictionary] = []
    var loaded: [NSDictionary] = []
    
    var avatarImagesDictionary: NSMutableDictionary?
    var avatarDictionary: NSMutableDictionary?
    
    var showAvatars: Bool = false
    var firstLoad: Bool?
    
    var withUser: BackendlessUser?
    var recent: NSDictionary?
    
    var chatRoomId: String!
    var initialLoadComlete: Bool = false
    
    let outgoingBubble = JSQMessagesBubbleImageFactory().outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    
    let incomingBubble = JSQMessagesBubbleImageFactory().incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    
    override func viewWillAppear(_ animated: Bool) {
        loadUserDefaults()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        ClearRecentCounter(chatRoomID: chatRoomId)
        ref.removeAllObservers()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.senderId = backendless?.userService.currentUser.objectId
        self.senderDisplayName = backendless?.userService.currentUser.name
        
        
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        if withUser?.objectId == nil {
            getWithUserFromRecent(recent: recent!, result: { (withUser) in
                self.withUser = withUser
                self.title = withUser.name
                self.getAvatars()
            })
        } else {
            self.title = withUser!.name
            self.getAvatars()
        }

        
        //load firebase messsages
        loadmessages()
        
        self.inputToolbar.contentView.textView.placeHolder = "type new message"
        
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

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let data = messages[indexPath.row]
        
        if data.senderId == backendless?.userService.currentUser.objectId {
            cell.textView?.textColor = UIColor.white
        } else {
            cell.textView?.textColor = UIColor.black
        }
        
        return cell
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        let data = messages[indexPath.row]
        return data
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        let data = messages[indexPath.row]
        
        if data.senderId == backendless?.userService.currentUser.objectId {
            return outgoingBubble
        } else {
            return incomingBubble
        }

    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        if indexPath.item % 3 == 0 {
            
            let message = messages[indexPath.item]
            
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        return nil
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellBottomLabelAt indexPath: IndexPath!) -> NSAttributedString! {
        let message = objects[indexPath.row]
        
        let status = message["status"] as! String
        
        if indexPath.row == (messages.count - 1) {
            return NSAttributedString(string: status)
        } else {
            return NSAttributedString(string: "")
        }

    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat {
        
        //why % 3 == 0 ???
        if indexPath.item % 3 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        return 0.0
    }


    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellBottomLabelAt indexPath: IndexPath!) -> CGFloat {
        if outgoing(item: objects[indexPath.row]) {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        } else {
            return 0.0
        }

    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        let message = messages[indexPath.row]
        let avatar = avatarDictionary!.object(forKey: message.senderId) as! JSQMessageAvatarImageDataSource
        
        return avatar

    }

    
    //MARK: JSQMessages Delegate function
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
        if text != "" {
            sendMessage(text: text, date: date, picture: nil, location: nil)
        }
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        let camera = Camera(delegate_: self)
        
        let optionMenu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let takePhoto = UIAlertAction(title: "Take Photo", style: .default) { (alert: UIAlertAction!) -> Void in
            camera.PresentPhotoCamera(target: self, canEdit: true)
        }
        
        let sharePhoto = UIAlertAction(title: "Photo Library", style: .default) { (alert: UIAlertAction!) -> Void in
            camera.PresentPhotoLibrary(target: self, canEdit: true)
        }
        
        let shareLoction = UIAlertAction(title: "Share Location", style: .default) { (alert: UIAlertAction!) -> Void in
            
            if self.haveAccessToLocation() {
                self.sendMessage(text: nil, date: NSDate(), picture: nil, location: "location")
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (alert : UIAlertAction!) -> Void in
            
            print("Cancel")
        }
        
        optionMenu.addAction(takePhoto)
        optionMenu.addAction(sharePhoto)
        optionMenu.addAction(shareLoction)
        optionMenu.addAction(cancelAction)
        
        self.present(optionMenu, animated: true, completion: nil)
    }
    
    //MARK: Send Message
    
    func sendMessage(text: String?, date: NSDate, picture: UIImage?, location: String?) {
        var outgoingMessage : OutgoingMessage?
        
        //if text message
        if let text = text {
            outgoingMessage = OutgoingMessage(message: text, senderId: (backendless?.userService.currentUser.objectId!)!, senderName: (backendless?.userService.currentUser.name!)!, date: date, status: "Delivered", type: "text")
        }
        
        //send picture message
        if let pic = picture {
            let imageData = UIImageJPEGRepresentation(pic, 1.0)
            
            outgoingMessage = OutgoingMessage(message: "Picture", pictureData: imageData!, senderId: (backendless?.userService.currentUser.objectId!)!, senderName: (backendless?.userService.currentUser.name!)!, date: date, status: "Delivered", type: "picture")
           
        }
        
        if let _ = location {
            let lat : NSNumber = NSNumber(value: (appDelegate.coordinate?.latitude)!)
            let lng: NSNumber = NSNumber(value: (appDelegate.coordinate?.longitude)!)
            
            outgoingMessage = OutgoingMessage(message: "Location", latitude: lat, longitude: lng, senderId: (backendless?.userService.currentUser.objectId!)!, senderName: (backendless?.userService.currentUser.name!)!, date: date, status: "Delivered", type: "location")
        }

        //play message sent sound
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        self.finishSendingMessage()
        
        
        outgoingMessage!.sendMessage(chatRoomID: chatRoomId, item: outgoingMessage!.messageDictionary)

    }
    
    //MARK: Load Messages
    
    func loadmessages() {
        
        ref.child(chatRoomId).observe(.childAdded, with: {
            snapshot in
            
            if snapshot.exists() {
                let item = (snapshot.value as? NSDictionary)!
                
                if self.initialLoadComlete {
                    let incoming = self.insertMessage(item: item)
                    
                    if incoming {
                        JSQSystemSoundPlayer.jsq_playMessageReceivedSound()
                    }
                    
                    self.finishReceivingMessage(animated: true)
                    
                } else {
                    self.loaded.append(item)
                }
            }
        })
        
        
        ref.child(chatRoomId).observe(.childChanged, with: {
            snapshot in
            
            //updated message
        })
        
        
        ref.child(chatRoomId).observe(.childRemoved, with: {
            snapshot in
            
            //Deleted message
        })
        
        ref.child(chatRoomId).observeSingleEvent(of: .value, with:{
            snapshot in
            
            self.insertMessages()
            self.finishReceivingMessage(animated: true)
            self.initialLoadComlete = true
        })
        
    }
    
    func insertMessages() {
        
        for item in loaded {
            //create message
            insertMessage(item: item)
        }
    }
    
    func insertMessage(item: NSDictionary) -> Bool {
        
        let incomingMessage = IncomingMessage(collectionView_: self.collectionView!)
        
        let message = incomingMessage.createMessage(dictionary: item)
        
        objects.append(item)
        messages.append(message!)
        
        return incoming(item: item)
    }
    
    func incoming(item: NSDictionary) -> Bool {
        
        if backendless?.userService.currentUser.objectId == item["senderId"] as? String {
            return false
        } else {
            return true
        }
    }
    
    func outgoing(item: NSDictionary) -> Bool {
        if backendless?.userService.currentUser.objectId == item["senderId"] as? String {
            return true
        } else {
            return false
        }
    }
    
    //MARK: Helper functions
    
    func haveAccessToLocation() -> Bool {
        if let _ = appDelegate.coordinate?.latitude {
            return true
        } else {
            print("no access to location")
            return false
        }
    }
    
    //MARK: UIIMagePickerController functions delegate
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        let picture = info[UIImagePickerControllerEditedImage] as! UIImage
        
        self.sendMessage(text: nil, date: NSDate(), picture: picture, location: nil)
        
        picker.dismiss(animated: true, completion: nil)
    }

    //MARK: JSQDelegate functions
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, didTapMessageBubbleAt indexPath: IndexPath!) {
        let object = objects[indexPath.row]
        
        if object["type"] as! String == "picture" {
            
            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! JSQPhotoMediaItem
            
            let photos = IDMPhoto.photos(withImages: [mediaItem.image])
            let browser = IDMPhotoBrowser(photos: photos)
            
            self.present(browser!, animated: true, completion: nil)
        }
        
        if object["type"] as! String == "location" {
            
            //self.navigationController?.performSegue(withIdentifier: "chatToMapSeg", sender: indexPath)//this will work, because self (this view controller) is push to root view is navigationController, so only root view will find this seg, so chatToMapSeg must connect from root view to map view and prepare(for segue) must implement in root view navigationController, not implement here
            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! JSQLocationMediaItem
            
            let mapVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MapVC") as! MapViewController
            
            //let mapView =  MapViewController()
            mapVC.location = mediaItem.location
            
            self.present(mapVC, animated: true, completion: nil)//not work if VC not init from UIStoryboard
            
            //navigationController?.pushViewController(mapView, animated: true)
            //self.performSegue(withIdentifier: "chatToMapSeg", sender: indexPath)
            /*
             MapViewController chi hien thi map khi init VC bang UIStoryboard hoac self.performSegue, neu ko khi goi self.present hay navigationController?.pushViewController no se ko len UI, co the UI da ko dc instantiate neu open viewcontroller theo cach nay.
             */
        }

    }
    
    //MARK: Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "chatToMapSeg" {
            
            let indexPath = sender as! NSIndexPath
            let message = messages[indexPath.row]
            
            let mediaItem = message.media as! JSQLocationMediaItem
            
            let mapView = segue.destination as! MapViewController
            mapView.location = mediaItem.location
        }
    }
    

    // AVATAR
    func getAvatars() {
        
        if showAvatars {
            
            print("showAvatar")
            collectionView?.collectionViewLayout.incomingAvatarViewSize = CGSize(width:40, height:40)
            collectionView?.collectionViewLayout.outgoingAvatarViewSize = CGSize(width:40, height:40)
            
            //download avatars
            avatarImageFromBackendlessUser(user: (backendless?.userService.currentUser)!)
            avatarImageFromBackendlessUser(user: withUser!)
            
            //create avatars
            createAvatars(avatars: avatarImagesDictionary)
        }
    }

    
    func createAvatars(avatars: NSMutableDictionary?) {
        
        var currentUserAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        var withUserAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(named: "avatarPlaceholder"), diameter: 70)
        
        
        if let avat = avatars {
            if let currentUserAvatarImage = avat.object(forKey: (backendless?.userService.currentUser.objectId)!) {
                
                currentUserAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: currentUserAvatarImage as! NSData as Data), diameter: 70)
                self.collectionView?.reloadData()
            }
        }
        
        if let avat = avatars {
            if let withUserAvatarImage = avat.object(forKey: withUser!.objectId!) {
                
                withUserAvatar = JSQMessagesAvatarImageFactory.avatarImage(with: UIImage(data: withUserAvatarImage as! NSData as Data), diameter: 70)
                self.collectionView?.reloadData()
            }
        }
        
        avatarDictionary = [(backendless?.userService.currentUser.objectId!)! : currentUserAvatar!, withUser!.objectId! : withUserAvatar!]
    }

    func avatarImageFromBackendlessUser(user: BackendlessUser) {
        
        let imageLink = user.getProperty("Avatar")
        let imageUrl = imageLink as? String
        
        if let imageUrl = imageUrl {
            
            getImageFromURL(url: imageUrl, result: { (image) -> Void in
                
                let imageData = UIImageJPEGRepresentation(image!, 1.0)
                
                if self.avatarImagesDictionary != nil {
                    
                    self.avatarImagesDictionary!.removeObject(forKey: user.objectId)
                    self.avatarImagesDictionary!.setObject(imageData!, forKey: user.objectId!)
                } else {
                    self.avatarImagesDictionary = [user.objectId! : imageData!]
                }
                self.createAvatars(avatars: self.avatarImagesDictionary)
                
            })
        }
    }
    
    func getWithUserFromRecent(recent: NSDictionary, result: (withUser: BackendlessUser) -> Void) {
        
        let withUserId = recent["withUserUserId"] as? String
        
        let whereClause = "objectId = '\(withUserId!)'"
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        
        let dataStore = backendless?.persistenceService.of(BackendlessUser.ofClass())
        
        dataStore?.find(dataQuery, response: { (users : BackendlessCollection?) -> Void in
            
            let withUser = users?.data.first as! BackendlessUser
            
            result(withUser: withUser)
            
        }) { (fault : Fault?) -> Void in
            print("Server report an error : \(fault)")
        }
    }

    //MARK: UserDefaults functions
    
    func loadUserDefaults() {
        firstLoad = userDefaults.bool(forKey: kFIRSTRUN)
        
        if !firstLoad! {
            userDefaults.set(true, forKey: kFIRSTRUN)
            userDefaults.set(showAvatars, forKey: kAVATARSTATE)
            userDefaults.synchronize()
        }
        
        showAvatars = userDefaults.bool(forKey: kAVATARSTATE)
    }


  
    
}
