//
//  ChooseUserViewController.swift
//  beechat
//
//  Created by Phan Nguyen on 8/30/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import UIKit

protocol ChooseUserDelegate {
    func createChatRoom(withUser:BackendlessUser)
}
class ChooseUserViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
    
    var users:[BackendlessUser] = []
    @IBOutlet weak var tableView: UITableView!
    var delegate: ChooseUserDelegate!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        loadUsers()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        let user = users[indexPath.row]
        cell.textLabel?.text = user.name
        return cell
    }
    
       
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let user = users[indexPath.row]
        delegate.createChatRoom(withUser: user)
        tableView.deselectRow(at: indexPath, animated: true)
        self.dismiss(animated: true, completion: nil)

    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

    @IBAction func cancelButtonPressed(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadUsers() {
        
        let currentId = backendless?.userService.currentUser.objectId
        let whereClause = "objectId!='\(currentId!)'"
        print(whereClause)
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        
        let dataStore = backendless?.persistenceService.of(BackendlessUser.ofClass())
        dataStore?.find(dataQuery, response: { (users : BackendlessCollection?) -> Void in
            
            self.users = users?.data as! [BackendlessUser]
            
            self.tableView.reloadData()
            
            
        }) { (fault : Fault?) -> Void in
            print("Error, couldnt retrive users: \(fault)")
        }
    }
    
    

}
