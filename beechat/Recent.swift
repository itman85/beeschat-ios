//
//  Recent.swift
//  beechat
//
//  Created by Phan Nguyen on 8/26/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import Foundation
import Firebase

//------Constants--------\\
public let kBADGENUMBER = "badgeNumber"
public let kAVATARSTATE = "avatarState"
public let kFIRSTRUN = "firstRun"
public let kDEVICETOKEN = "deviceToken"
public let kREGISTERDEVICE = "deviceRegister"//true if device already register to backend less
//--------\\
var firebase = FIRDatabase.database().reference()
let backendless = Backendless.sharedInstance()
//let currentUser = backendless?.userService.currentUser

extension Data {
    func hexString() -> String {
        return self.reduce("") { string, byte in
            string + String(format: "%02X", byte)
        }
    }
}

//MARK: Create Chatroom

func startChat(user1: BackendlessUser, user2: BackendlessUser) -> String {
    
    //user 1 is current user
    let userId1: String = user1.objectId
    let userId2: String = user2.objectId
    
    var chatRoomId: String = ""
    
    let value = userId1.compare(userId2).rawValue
    
    if value < 0 {
        chatRoomId = userId1 + userId2
    } else {
        chatRoomId = userId2 + userId1
    }
    
    let members = [userId1, userId2]
    
    //create recent
    CreateRecent(userId: userId2, chatRoomID: chatRoomId, members: members, withUserUsername: user1.name!, withUseruserId: userId1)
    CreateRecent(userId: userId1, chatRoomID: chatRoomId, members: members, withUserUsername: user2.name!, withUseruserId: userId2)
    
    return chatRoomId
}


//MARK: Create RecentItem
//MARK: Create RecentItem

func CreateRecent(userId: String, chatRoomID: String, members: [String], withUserUsername: String, withUseruserId: String) {
    
    print("Create recent for chatroom id \(chatRoomID)")
    //CreateRecentItem(userId: userId, chatRoomID: chatRoomID, members: members, withUserUsername: withUserUsername, withUserUserId: withUseruserId)
    
    firebase.child("Recent").queryOrdered(byChild: "chatRoomID").queryEqual(toValue: chatRoomID).observeSingleEvent(of: .value, with:{
        snapshot in
        
        print("Firebase Query Recent response result for user id \(userId)")
        
        var createRecent = true
        
        //check if we have a result
        if snapshot.exists() {
            for recent in snapshot.value!.allValues {
                print(recent)
                //if we already have recent with passed userId, we dont create a new one
                if recent["userId"] as! String == userId {
                    createRecent = false
                }
            }
        }
        
        if createRecent {
            print("*** CreateRecent for userId \(userId)")
            CreateRecentItem(userId: userId, chatRoomID: chatRoomID, members: members, withUserUsername: withUserUsername, withUserUserId: withUseruserId)
        }
    })
}


func CreateRecentItem(userId: String, chatRoomID: String, members: [String], withUserUsername: String, withUserUserId: String) {
    
    let ref = firebase.child("Recent").childByAutoId()
    
    let recentId = ref.key
    let date = dateFormatter().string(from: Date())
    print("FIREBASE going to save recent item id \(recentId) At \(date)")
    
    let recent = ["recentId" : recentId, "userId" : userId, "chatRoomID" : chatRoomID, "members" : members, "withUserUsername" : withUserUsername, "lastMessage" : "", "counter" : 0, "date" : date, "withUserUserId" : withUserUserId]
    
    //save to firebase
    ref.setValue(recent) { (error, ref) -> Void in
        if error != nil {
            print("error creating recent \(error)")
        }else{
            print("FIREBASE save recent item OK")
        }
    }
}

//MARK: Update Recent

func UpdateRecents(chatRoomID: String, lastMessage: String) {
    
    firebase.child("Recent").queryOrdered(byChild: "chatRoomID").queryEqual(toValue: chatRoomID).observeSingleEvent(of: .value, with: {
        snapshot in
        
        if snapshot.exists() {
            
            for recent in snapshot.value!.allValues {
                UpdateRecentItem(recent: recent as! NSDictionary, lastMessage: lastMessage)
            }
        }
    })
}

func UpdateRecentItem(recent: NSDictionary, lastMessage: String) {
    let date = dateFormatter().string(from: NSDate() as Date)
    
    var counter = recent["counter"] as! Int
    
    if recent["userId"] as? String != backendless?.userService.currentUser.objectId {
        counter += 1
    }
    
    let values = ["lastMessage" : lastMessage, "counter" : counter, "date" : date]
    
    //change
    firebase.child("Recent").child((recent["recentId"] as? String)!).updateChildValues(values as [NSObject : AnyObject], withCompletionBlock: {
        (error, ref) -> Void in
        
        if error != nil {
            print("Error couldnt update recent item")
        }
    })
}



//MARK: Restart Recent Chat

func RestartRecentChat(recent: NSDictionary) {
    
    
    for userId in recent["members"] as! [String] {
        
        if userId != backendless?.userService.currentUser.objectId {
            
            print("*** RestartRecentChat for userId \(userId)")
            CreateRecent(userId: userId, chatRoomID: (recent["chatRoomID"] as? String)!, members: recent["members"] as! [String], withUserUsername: (backendless?.userService.currentUser.name)!, withUseruserId: (backendless?.userService.currentUser.objectId)!)
        }
    }
}

//MARK: Delete Recent functions

func DeleteRecentItem(recent: NSDictionary) {
    firebase.child("Recent").child((recent["recentId"] as? String)!).removeValue { (error, ref) -> Void in
        if error != nil {
            print("Error deleting recent item: \(error)")
        }
    }
}

//MARK: Clear recent counter function

func ClearRecentCounter(chatRoomID: String) {
    firebase.child("Recent").queryOrdered(byChild: "chatRoomID").queryEqual(toValue: chatRoomID).observeSingleEvent(of: .value, with: {
        snapshot in
        
        if snapshot.exists() {
            for recent in snapshot.value!.allValues {
                if recent["userId"] as? String == backendless?.userService.currentUser.objectId {
                    ClearRecentCounterItem(recent: recent as! NSDictionary)
                }
            }
        }
    })
}

func ClearRecentCounterItem(recent: NSDictionary) {
    
    firebase.child("Recent").child((recent["recentId"] as? String)!).updateChildValues(["counter" : 0]) { (error, ref) -> Void in
        if error != nil {
            print("Error couldnt update recents counter: \(error!.localizedDescription)")
        }
    }
}


func TimeElapsed(seconds: TimeInterval) -> String {
    let elapsed: String?
    
    if (seconds < 60) {
        elapsed = "Just now"
    } else if (seconds < 60 * 60) {
        let minutes = Int(seconds / 60)
        
        var minText = "min"
        if minutes > 1 {
            minText = "mins"
        }
        elapsed = "\(minutes) \(minText)"
        
    } else if (seconds < 24 * 60 * 60) {
        let hours = Int(seconds / (60 * 60))
        var hourText = "hour"
        if hours > 1 {
            hourText = "hours"
        }
        elapsed = "\(hours) \(hourText)"
    } else {
        let days = Int(seconds / (24 * 60 * 60))
        var dayText = "day"
        if days > 1 {
            dayText = "days"
        }
        elapsed = "\(days) \(dayText)"
    }
    return elapsed!
}


private let dateFormat = "yyyyMMddHHmmss"

func dateFormatter() -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = dateFormat
    
    return dateFormatter
}
