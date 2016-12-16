//
//  RecentTableViewCell.swift
//  beechat
//
//  Created by Phan Nguyen on 8/25/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import UIKit

class RecentTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    
    @IBOutlet weak var lastMsgLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var counterLabel: UILabel!
    
    @IBOutlet weak var avatarImgView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func bindData(_ recent:NSDictionary){
        avatarImgView.layer.cornerRadius = avatarImgView.frame.size.width/2
        avatarImgView.layer.masksToBounds = true
        self.avatarImgView.image = UIImage(named: "avatarPlaceholder")
        let withUserId = recent.object(forKey: "withUserUserId") as? String
        
        let whereClause = "objectId='\(withUserId!)'"
        print(whereClause)
        let dataQuery = BackendlessDataQuery()
        dataQuery.whereClause = whereClause
        
        let dataStore = backendless?.persistenceService.of(BackendlessUser.ofClass())
        dataStore?.find(dataQuery, response: { (users : BackendlessCollection?) -> Void in
            
             print("Start get avatar for cell")
            let withUser = users?.data.first as! BackendlessUser
            let imageLink = withUser.getProperty("Avatar")
            let imageUrl = imageLink as? String
            
            if let avatarURL = imageUrl {
                getImageFromURL(url: avatarURL, result: { (image) -> Void in
                    print("get avatar ok for cell")
                    self.avatarImgView.image = image
                })
            }
            
        }) { (fault: Fault?) -> Void in
            print("error, couldnt get user avatar: \(fault)")
        }
        
        nameLabel.text = recent["withUserUsername"] as? String
        lastMsgLabel.text = recent["lastMessage"] as? String
        counterLabel.text = ""
        if (recent["counter"] as? Int)! != 0 {
            counterLabel.text = "\(recent["counter"]!) New"
        }
        
        let date = dateFormatter().date(from: (recent["date"] as? String)!)
        let seconds = Date().timeIntervalSince(date!)
        dateLabel.text = TimeElapsed(seconds: seconds)


    }

}
