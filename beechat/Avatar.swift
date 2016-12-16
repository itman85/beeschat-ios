//
//  Avatar.swift
//  beechat
//
//  Created by Phan Nguyen on 9/3/16.
//  Copyright © 2016 Omebee. All rights reserved.
//

import Foundation
func uploadAvatar(image:UIImage,result:(imageLink:String?)->Void){
    let imageData = UIImageJPEGRepresentation(image, 1.0)
    
    let dateString = dateFormatter().string(from: Date())
    
    let fileName = "Img/" + dateString + ".jpeg"
    
    backendless?.fileService.upload(fileName, content: imageData, response: { (file) -> Void in
        
        result(imageLink: file!.fileURL)
        
    }) { (fault : Fault?) -> Void in
        print("error uploading avatar image : \(fault)")
    }

}

func getImageFromURL(url: String, result: (image: UIImage?) ->Void) {
    
    print("getImageFromURL \(url)")
    let Url = URL(string: url)
    
    let downloadQue = DispatchQueue(label:"imageDownloadQue", attributes: .concurrent)
    
    if Url != nil{
        downloadQue.async() { () -> Void in
            print("Start downloading image")
            let data = NSData(contentsOf:Url!)
            
            let image: UIImage!
            
            if data != nil {
                print("Download image complete")
                image = UIImage(data: data! as Data)
                
                DispatchQueue.main.async() {
                    print("Callback result now")
                    result(image: image)
                }
            }
        }
    }
}
