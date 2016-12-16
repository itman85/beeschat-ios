//
//  RegisterFBUser.swift
//  beechat
//
//  Created by Phan Nguyen on 9/5/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import Foundation

var isSimulator: Bool {
    return TARGET_OS_SIMULATOR != 0 // Use this line in Xcode 7 or newer
    //return TARGET_IPHONE_SIMULATOR != 0 // Use this line in Xcode 6
}

func shouldRegisterDeviceAgain(){
    if isSimulator{
        print("Simulator running")
        return
    }
    print("Should Register Device Again???")
    let isRegisteredDevice = UserDefaults.standard.bool(forKey: kREGISTERDEVICE)
    if !isRegisteredDevice{
        print("Register Device to backend less again")
        let deviceToken = UserDefaults.standard.data(forKey: kDEVICETOKEN)
        if let deviceToken = deviceToken{
            print("Sending device token to backend less again ...")
            backendless?.messagingService.registerDeviceToken(deviceToken)
        }
    }
    
}
func registerUserDeviceId() {
    if isSimulator{
        print("Simulator running")
        return
    }
    
    shouldRegisterDeviceAgain()
    
    if (backendless?.messagingService.getRegistration().deviceId != nil) {
        
        let deviceId = (backendless?.messagingService.getRegistration().deviceId)! as String
        
        let properties = ["deviceId" : deviceId]
        
        backendless?.userService.currentUser!.updateProperties(properties)
        backendless?.userService.update(backendless?.userService.currentUser)
    }
    
}

func updateBackendlessUser(facebookId: String, avatarUrl: String) {
    if isSimulator{
        print("Simulator running")
        return
    }

    
    /*let whereClause = "facebookId = '\(facebookId)'"
    
    let dataQuery = BackendlessDataQuery()
    dataQuery.whereClause = whereClause
    
    let dataStore = backendless?.persistenceService.of(BackendlessUser.ofClass())
    dataStore?.find(dataQuery, response: { (users : BackendlessCollection?) -> Void in
        
        let user = users?.data.first as! BackendlessUser
        
        let properties = ["Avatar" : avatarUrl]
        
        user.updateProperties(properties)
        
        backendless?.userService.update(user)//
        
    }) { (fault : Fault?) -> Void in
        print("Error, couldnt retrive FB users: \(fault)")
    }*/

    
    var properties: [String: String]!
    
    if backendless?.messagingService.getRegistration().deviceId != nil {
        let deviceId = backendless?.messagingService.getRegistration().deviceId
        
        properties = ["Avatar" : avatarUrl, "deviceId" : deviceId!]
    } else {
        properties = ["Avatar" : avatarUrl]
    }
    
    
    backendless?.userService.currentUser.updateProperties(properties)
     print("Start updated Fb user")
    backendless?.userService.update(backendless!.userService.currentUser, response: { (updatedUser: BackendlessUser?) -> Void in
        print("updated user is : \(updatedUser!)")
        }, error: { (fault : Fault?) -> Void in
            print("Error couldnt update the devices id: \(fault)")
    })
    
    
    
}


func removeDeviceIdFromUser() {
    
    if isSimulator{
        print("Simulator running")
        return
    }

    print("Remove device info from user in backendless")
    let properties = ["deviceId" : ""]
    
    backendless?.userService.currentUser!.updateProperties(properties)
    backendless?.userService.update(backendless?.userService.currentUser)
    
    
}
