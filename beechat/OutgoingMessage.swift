//
//  OutgoingMessage.swift
//  beechat
//
//  Created by Phan Nguyen on 8/31/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import Foundation
class OutgoingMessage {
    private let ref = firebase.child("Message")
    let messageDictionary: NSMutableDictionary
    
    init (message: String, senderId: String, senderName: String, date: NSDate, status: String, type: String) {
        
        messageDictionary = NSMutableDictionary(objects: [message, senderId, senderName, dateFormatter().string(from: date as Date), status, type], forKeys: ["message", "senderId", "senderName", "date", "status", "type"])
    }
    
    init(message: String, latitude: NSNumber, longitude: NSNumber, senderId: String, senderName: String, date: NSDate, status: String, type: String) {
        
        messageDictionary = NSMutableDictionary(objects: [message, latitude, longitude, senderId, senderName, dateFormatter().string(from: date as Date), status, type], forKeys: ["message", "latitude", "longitude", "senderId", "senderName", "date", "status", "type"])
    }
    
    init (message: String, pictureData: NSData, senderId: String, senderName: String, date: NSDate, status: String, type: String) {
        
        let pic = pictureData.base64EncodedString(options: NSData.Base64EncodingOptions(rawValue: 0))
        
        
        messageDictionary = NSMutableDictionary(objects: [message, pic, senderId, senderName, dateFormatter().string(from: date as Date), status, type], forKeys: ["message", "picture", "senderId", "senderName", "date", "status", "type"])
    }
    
    func sendMessage(chatRoomID: String, item: NSMutableDictionary) {
        
        let reference = ref.child(chatRoomID).childByAutoId()
        
        item["messageId"] = reference.key
        
        reference.setValue(item) { (error, ref) -> Void in
            if error != nil {
                print("Error, couldnt send message")
            }else{
                print("Send message to firebase ok, so push message now")
                SendPushNotification(chatRoomID: chatRoomID, message: (item["message"] as? String)!)
            }
        }
        UpdateRecents(chatRoomID: chatRoomID, lastMessage: (item["message"] as? String)!)
    }

}
