//
//  PushNotifications.swift
//  beechat
//
//  Created by Phan Nguyen on 9/6/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import Foundation


func SendPushNotification(chatRoomID: String, message: String) {
    
    firebase.child("Recent").queryOrdered(byChild: "chatRoomID").queryEqual(toValue: chatRoomID).observeSingleEvent(of: .value, with: {
        snapshot in
        
        if snapshot.exists() {
            let recents = snapshot.value!.allValues
            
            if let recent = recents?.first {
                SendPush(members: (recent["members"] as? [String])!, message: message)
            }
        }
    })
}

func SendPush(members:[String], message: String) {
    
    let withUserId = getWithUserIdFromArray(users: members)!
    
    let whereClause = "objectId = '\(withUserId)'"
    let queryData = BackendlessDataQuery()
    queryData.whereClause = whereClause
    
    let dataStore = backendless?.persistenceService.of(BackendlessUser.ofClass())
    
    dataStore?.find(queryData, response: { (users) -> Void in
        
        let withUser = users?.data.first as! BackendlessUser
        
        SendPushMessage(toUser: withUser, message: message)
        
    }) { (fault : Fault?) -> Void in
        print("error, couldnt get user from users table")
    }
    
}



//use backendless api to send push message
func SendPushMessage(toUser: BackendlessUser, message: String) {
    
    let deviceId = toUser.getProperty("deviceId") as! String
    
    let deliveryOptions = DeliveryOptions()
    deliveryOptions.pushSinglecast = [deviceId]
    deliveryOptions.pushPolicy(PUSH_ONLY)
    
    let publishOptions = PublishOptions()
    publishOptions.assignHeaders(["ios-alert" : "New message from \(backendless!.userService.currentUser.name!) \n \(message)", "ios-badge" : "1", "ios-sound" : "default","ios-content-available":"1"])
    
    backendless?.messagingService.publish("default", message: message, publishOptions: publishOptions, deliveryOptions: deliveryOptions)
}

func getWithUserIdFromArray(users: [String]) -> String? {
    
    var id: String?
    
    for userId in users {
        if userId != backendless?.userService.currentUser.objectId {
            id = userId
        }
    }
    return id
}

func PushUserResign() {
    
    backendless?.messagingService.unregisterDeviceAsync({ (result) -> Void in
        UserDefaults.standard.set(false, forKey: kREGISTERDEVICE)
        UserDefaults.standard.synchronize()
        print("unregistered device token")
    }) { (fault: Fault?) -> Void in
        print("error couldnt unregister device token:\(fault)")
    }
}


