//
//  RecentViewController.swift
//  beechat
//
//  Created by Phan Nguyen on 8/25/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import UIKit

class RecentViewController: UIViewController,UITableViewDataSource,UITableViewDelegate,ChooseUserDelegate {

    @IBOutlet weak var tableView: UITableView!
    
    var recents: [NSDictionary] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadRecents()
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "recentToChooseUserVC"{
            let vc = segue.destination as! ChooseUserViewController
            vc.delegate = self
        }else if segue.identifier == "recentToChatSeq"{
            let indexPath = sender as! IndexPath
            let chatVC = segue.destination as! ChatViewController
            chatVC.hidesBottomBarWhenPushed = true        
            
            let recent = recents[indexPath.row]
            chatVC.recent = recent
            chatVC.chatRoomId = recent["chatRoomID"] as? String
            
        }
        
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    //start new chat room
    @IBAction func startNewChatPress(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "recentToChooseUserVC", sender: self)
        
        /*
         //neu open ChooseUserViewController theo cach nay thi cac control iboutlet se nil
         let vc = ChooseUserViewController()
        vc.delegate = self
        navigationController?.pushViewController(vc, animated: true)*/
    }

    
    // UITableviewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return recents.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! RecentTableViewCell
        let recent = recents[indexPath.row]
        cell.bindData(recent)
        return cell
    }
    
    /*
     start chat from recent message
     */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        //create recent for both user2
        let recent = recents[indexPath.row]
        RestartRecentChat(recent: recent)
        
        let chatVC = ChatViewController()
        chatVC.hidesBottomBarWhenPushed = true
        
        chatVC.recent = recent
        chatVC.chatRoomId = recent["chatRoomID"] as? String
        navigationController?.pushViewController(chatVC, animated: true)//open ChatVC by push will NOT find segue chatToMapSeg to perform open Map View Controller
        
        //performSegue(withIdentifier: "recentToChatSeq", sender: indexPath)//open ChatVC this way will find segue chatToMapSeg to perform open Map View Controller
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        let recent = recents[indexPath.row]
        
        recents.remove(at: indexPath.row)
        
        DeleteRecentItem(recent: recent)
        
        tableView.reloadData()
    }
    func createChatRoom(withUser: BackendlessUser) {
        let chatVC = ChatViewController()
        chatVC.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(chatVC, animated: true)//??? tai sao let chatVC = ChatViewController() nhung lai hien thi dc UI con MapViewController thi ko
        chatVC.withUser = withUser
        chatVC.chatRoomId = startChat(user1: (backendless!.userService.currentUser)!, user2: withUser)
        
    }
    
    //MARK: Load Recents from firebase
    
    func loadRecents() {
        firebase.child("Recent").queryOrdered(byChild: "userId").queryEqual(toValue: backendless?.userService.currentUser.objectId).observe(.value, with: {
            snapshot in
            
             print("*** Firsebase observe  userId value callback for Name: \(backendless?.userService.currentUser.name)")
            
            //clear all
            self.recents.removeAll()
            
            if snapshot.exists() {
                
                let sorted = (snapshot.value!.allValues as NSArray).sortedArray(using: [NSSortDescriptor(key: "date", ascending: false)])
                
                for recent in sorted {
                    print(recent)
                    self.recents.append(recent as! NSDictionary)
                    
                    //add function to have offline access as well, this will download with user recent as well so that we will not create it again
                    
                   /* firebase.child("Recent").queryOrdered(byChild: "chatRoomID").queryEqual(toValue: recent["chatRoomID"]).observe(.value, with: {
                        snapshot in
                        //this query will get all recent of this chat room and store in local, and then when it query, it will find withuser have already had recent, so will not create new recent item for withuser
                        print("*** Firsebase observe  chatRoomID value callback for chatRoomID: \(recent["chatRoomID"])")
                    })*/
                    
                }
                
            }
            
            self.tableView.reloadData()
        })
        
    }


}
