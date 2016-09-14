//
//  QiscusCommentClient.swift
//  QiscusSDK
//
//  Created by ahmad athaullah on 7/17/16.
//  Copyright © 2016 qiscus. All rights reserved.
//

import Foundation
import UIKit
import PusherSwift
import Alamofire
import AlamofireImage
import SwiftyJSON
import AVFoundation
import Photos

let qiscus = Qiscus.sharedInstance

public class QiscusCommentClient: NSObject {
    public static let sharedInstance = QiscusCommentClient()
    
    public var commentDelegate: QCommentDelegate?
    public var roomDelegate: QiscusRoomDelegate?
    public var configDelegate: QiscusConfigDelegate?
    
    // MARK: - Login or register
    public func loginOrRegister(email:String = "", password:String = "", username:String? = nil, avatarURL:String? = nil){
        let manager = Alamofire.Manager.sharedInstance
        var parameters:[String: AnyObject] = [String: AnyObject]()
        
        parameters = [
            "email"  : email,
            "password" : password,
        ]
        
        if let name = username{
            parameters["username"] = name
        }
        if let avatar =  avatarURL{
            parameters["avatar_url"] = avatar
        }
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let request = manager.request(.POST, QiscusConfig.LOGIN_REGISTER, parameters: parameters, encoding: ParameterEncoding.URL, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON { response in
                print("login register result: \(response)")
                print("login url: \(QiscusConfig.LOGIN_REGISTER)")
                print("post parameters: \(parameters)")
                print("post headers: \(QiscusConfig.sharedInstance.requestHeader)")
                switch response.result {
                case .Success:
                    dispatch_async(dispatch_get_main_queue()) {
                        if let result = response.result.value {
                            let json = JSON(result)
                            let success = (json["status"].intValue == 200)
                            
                            if success == true {
                                let userData = json["results"]["user"]
                                QiscusMe.saveData(fromJson: userData)
                                if self.configDelegate != nil {
                                    Qiscus.setupReachability()
                                    self.configDelegate!.qiscusConnected()
                                }
                            }
                        }else{
                            if self.configDelegate != nil {
                                self.configDelegate!.qiscusFailToConnect("Can't get data from qiscus")
                            }
                        }
                    }
                    break
                case .Failure(_):
                    dispatch_async(dispatch_get_main_queue()) {
                        if self.configDelegate != nil {
                            self.configDelegate!.qiscusFailToConnect("Can't get data from qiscus")
                        }
                    }
                }
            }
            request.resume()
        }
    }
    
    // MARK: - Comment Methode
    public func postMessage(message message: String, topicId: Int, roomId:Int? = nil){ //USED
        let comment = QiscusComment.newCommentWithMessage(message: message, inTopicId: topicId)
        self.postComment(comment, roomId: roomId)
        self.commentDelegate?.gotNewComment([comment])
    }
    public func postComment(comment:QiscusComment, file:QiscusFile? = nil, roomId:Int? = nil){ //USED
        
        let manager = Alamofire.Manager.sharedInstance
        var parameters:[String: AnyObject] = [String: AnyObject]()
        
        parameters = [
            "comment"  : comment.commentText,
            "topic_id" : comment.commentTopicId,
            "unique_temp_id" : comment.commentUniqueId
        ]
        
        if QiscusConfig.sharedInstance.requestHeader == nil{
            parameters["token"] = qiscus.config.USER_TOKEN
        }
        if roomId != nil {
            parameters["room_id"] = roomId
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let request = manager.request(.POST, QiscusConfig.postCommentURL, parameters: parameters, encoding: ParameterEncoding.URL, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON { response in
                print("post message result: \(response)")
                print("post url: \(QiscusConfig.postCommentURL)")
                print("post parameters: \(parameters)")
                print("post headers: \(QiscusConfig.sharedInstance.requestHeader)")
                switch response.result {
                    case .Success:
                        dispatch_async(dispatch_get_main_queue()) {
                            if let result = response.result.value {
                                let json = JSON(result)
                                let success = (json["status"].intValue == 200)
                                
                                if success == true {
                                    let commentJSON = json["results"]["comment"]
                                    comment.updateCommentId(commentJSON["id"].intValue)
                                    comment.updateCommentStatus(QiscusCommentStatus.Sent)
                                    let commentBeforeid = QiscusComment.getCommentBeforeIdFromJSON(commentJSON)
                                    if(QiscusComment.isValidCommentIdExist(commentBeforeid)){
                                        comment.updateCommentIsSync(true)
                                    }else{
                                        self.syncMessage(comment.commentTopicId)
                                    }
                                    
                                    self.commentDelegate?.didSuccesPostComment(comment)
                                    
                                    if file != nil {
                                        let thisComment = QiscusComment.getCommentByLocalId(comment.localId)
                                        if(file != nil){
                                            file?.updateCommentId(thisComment!.commentId)
                                        }
                                        
                                        self.commentDelegate?.didSuccessPostFile(comment)
                                    }
                                }
                            }else{
                                comment.updateCommentStatus(QiscusCommentStatus.Failed)
                                self.commentDelegate?.didFailedPostComment(comment)
                                
                                if file != nil{
                                    let thisComment = QiscusComment.getCommentByLocalId(comment.localId)
                                    if(file != nil){
                                        file?.updateCommentId(thisComment!.commentId)
                                    }
                                    self.commentDelegate?.didFailedPostFile(comment)
                                }
                            }
                        }
                        break
                    case .Failure(_):
                        dispatch_async(dispatch_get_main_queue()) {
                            comment.updateCommentStatus(QiscusCommentStatus.Failed)
                            self.commentDelegate?.didFailedPostComment(comment)
                            if file != nil{
                                let thisComment = QiscusComment.getCommentByLocalId(comment.localId)
                                if(file != nil){
                                    file?.updateCommentId(thisComment!.commentId)
                                }
                                self.commentDelegate?.didFailedPostFile(comment)
                        }
                    }
                }
            }
            request.resume()
        }
    }
    
    public func downloadMedia(comment:QiscusComment, thumbImageRef:UIImage? = nil){
        let file = QiscusFile.getCommentFile(comment.commentFileId)!
        let manager = Alamofire.Manager.sharedInstance
        
        //let headers = QiscusConfig.requestHeader
        
        file.updateIsDownloading(true)
        manager.request(.GET, (file.fileURL as String), parameters: nil, encoding: ParameterEncoding.URL, headers: QiscusConfig.sharedInstance.requestHeader)
            .progress{bytesRead, totalBytesRead, totalBytesExpectedToRead in
                let progress = CGFloat(CGFloat(totalBytesRead) / CGFloat(totalBytesExpectedToRead))
                
                dispatch_async(dispatch_get_main_queue()) {
                    print("Download progress: \(progress)")
                    file.updateDownloadProgress(progress)
                    self.commentDelegate?.downloadingMedia(comment)
                }
            }
            .responseData { response in
                if let fileData:NSData = response.data{
                    if let image:UIImage = UIImage(data: fileData) {
                        var thumbImage = UIImage()
                        if !(file.fileExtension == "gif" || file.fileExtension == "gif_"){
                            thumbImage = QiscusFile.createThumbImage(image, fillImageSize: thumbImageRef)
                        }
                        dispatch_async(dispatch_get_main_queue()) {
                            file.updateDownloadProgress(1.0)
                            file.updateIsDownloading(false)
                        }
                        print("Download finish")
                        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
                        let fileName = "\(comment.commentId)-Q-\(file.fileName as String)"
                        let path = "\(documentsPath)/\(fileName)"
                        let thumbPath = "\(documentsPath)/thumb_\(fileName)"

                        if (file.fileExtension == "png" || file.fileExtension == "png_") {
                            UIImagePNGRepresentation(image)!.writeToFile(path, atomically: true)
                            UIImagePNGRepresentation(thumbImage)!.writeToFile(thumbPath, atomically: true)
                        } else if(file.fileExtension == "jpg" || file.fileExtension == "jpg_"){
                            UIImageJPEGRepresentation(image, 1.0)!.writeToFile(path, atomically: true)
                            UIImageJPEGRepresentation(thumbImage, 1.0)!.writeToFile(thumbPath, atomically: true)
                        } else if(file.fileExtension == "gif" || file.fileExtension == "gif_"){
                            fileData.writeToFile(path, atomically: true)
                            fileData.writeToFile(thumbPath, atomically: true)
                            thumbImage = image
                        }
                        dispatch_async(dispatch_get_main_queue()) {
                            file.updateLocalPath(path)
                            file.updateThumbPath(thumbPath)
                            
                            self.commentDelegate?.didDownloadMedia(comment)
                        }
                        
                    }else{
                        let documentsPath = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true)[0] as String
                        let path = "\(documentsPath)/\(file.fileName as String)"
                        let thumbPath = "\(documentsPath)/thumb_\(file.fileCommentId).png"
                        
                        fileData.writeToFile(path, atomically: true)
                        
                        let assetMedia = AVURLAsset(URL: NSURL(string: "file://\(path)")!)
                        let thumbGenerator = AVAssetImageGenerator(asset: assetMedia)
                        thumbGenerator.appliesPreferredTrackTransform = true
                        
                        let thumbTime = CMTimeMakeWithSeconds(0, 30)
                        let maxSize = CGSizeMake(file.screenWidth, file.screenWidth)
                        thumbGenerator.maximumSize = maxSize
                        var thumbImage:UIImage?
                        do{
                            let thumbRef = try thumbGenerator.copyCGImageAtTime(thumbTime, actualTime: nil)
                            thumbImage = UIImage(CGImage: thumbRef)
                            
                            let thumbData = UIImagePNGRepresentation(thumbImage!)
                            thumbData?.writeToFile(thumbPath, atomically: true)
                        }catch{
                            print("error creating thumb image")
                        }
                        dispatch_async(dispatch_get_main_queue()){
                            file.updateDownloadProgress(1.0)
                            file.updateIsDownloading(false)
                            file.updateLocalPath(path)
                            file.updateThumbPath(thumbPath)
                            self.commentDelegate?.didDownloadMedia(comment)
                        }
                    }
                }
        }
    }
    public func uploadImage(topicId: Int,image:UIImage?,imageName:String,imagePath:NSURL? = nil, imageNSData:NSData? = nil, roomId:Int? = nil, thumbImageRef:UIImage? = nil){
        var imageData:NSData = NSData()
        if imageNSData != nil {
            imageData = imageNSData!
        }
        var thumbData:NSData = NSData()
        var imageMimeType:String = ""
        print("imageName: \(imageName)")
        let imageNameArr = imageName.characters.split(".")
        let imageExt:String = String(imageNameArr.last!).lowercaseString
        let comment = QiscusComment.newCommentWithMessage(message: "", inTopicId: topicId)
        
        if image != nil {
            var thumbImage = UIImage()
            print("\(imageName) --- \(imageExt) -- \(imageExt != "gif")")
            
            let isGifImage:Bool = (imageExt == "gif" || imageExt == "gif_")
            let isJPEGImage:Bool = (imageExt == "jpg" || imageExt == "jpg_")
            let isPNGImage:Bool = (imageExt == "png" || imageExt == "png_")
            
            print("\(imagePath)")
            
            if !isGifImage{
                thumbImage = QiscusFile.createThumbImage(image!, fillImageSize: thumbImageRef)
            }
            
            
            
            if isJPEGImage == true{
                let imageSize = image?.size
                var bigPart = CGFloat(0)
                if(imageSize?.width > imageSize?.height){
                    bigPart = (imageSize?.width)!
                }else{
                    bigPart = (imageSize?.height)!
                }
                
                var compressVal = CGFloat(1)
                if(bigPart > 2000){
                    compressVal = 2000 / bigPart
                }
                
                imageData = UIImageJPEGRepresentation(image!, compressVal)!
                thumbData = UIImageJPEGRepresentation(thumbImage, 1)!
                imageMimeType = "image/jpg"
            }else if isPNGImage == true{
                imageData = UIImagePNGRepresentation(image!)!
                thumbData = UIImagePNGRepresentation(thumbImage)!
                imageMimeType = "image/png"
            }else if isGifImage == true{
                if imageNSData == nil{
                    let asset = PHAsset.fetchAssetsWithALAssetURLs([imagePath!], options: nil)
                    if let phAsset = asset.firstObject as? PHAsset {
                        
                        let option = PHImageRequestOptions()
                        option.synchronous = true
                        option.networkAccessAllowed = true
                        PHImageManager.defaultManager().requestImageDataForAsset(phAsset, options: option) {
                            (data, dataURI, orientation, info) -> Void in
                            imageData = data!
                            thumbData = data!
                            imageMimeType = "image/gif"
                        }
                    }
                }else{
                    imageData = imageNSData!
                    thumbData = imageNSData!
                    imageMimeType = "image/gif"
                }
            }
        }else{
            if let mime:String = QiscusFileHelper.mimeTypes["\(imageExt)"] {
                imageMimeType = mime
                print("mime: \(mime)")
            }
        }
        let imageThumbName = "thumb_\(comment.commentUniqueId).\(imageExt)"
        let fileName = "\(comment.commentUniqueId).\(imageExt)"
        
        let commentFile = QiscusFile()
        if image != nil {
            commentFile.fileLocalPath = QiscusFile.saveFile(imageData, fileName: fileName)
            commentFile.fileThumbPath = QiscusFile.saveFile(thumbData, fileName: imageThumbName)
        }else{
            commentFile.fileLocalPath = imageName
        }
        commentFile.fileTopicId = topicId
        commentFile.isUploading = true
        commentFile.uploaded = false
        commentFile.saveCommentFile()
        
        comment.updateCommentText("[file]\(fileName) [/file]")
        comment.updateCommentFileId(commentFile.fileId)
        
        commentFile.updateIsUploading(true)
        commentFile.updateUploadProgress(0.0)
        
        self.commentDelegate?.gotNewComment([comment])
        
        let headers = QiscusConfig.sharedInstance.requestHeader
        
        Alamofire.upload(.POST,
                         QiscusConfig.UPLOAD_URL,
                         headers: headers,
                         multipartFormData: { multipartFormData in
                            multipartFormData.appendBodyPart(data: imageData, name: "file", fileName: "\(fileName)", mimeType: "\(imageMimeType)")
            }, encodingCompletion: { encodingResult in
                print("encodingResult: \(encodingResult)")
                switch encodingResult {
                case .Success(let upload, _, _):
                    upload.responseJSON { response in
                        print("success upload: \(response)")
                        if let JSON = response.result.value {
                            print(JSON)
                            let responseDictionary = JSON as! NSDictionary
                            print(responseDictionary)
                            if let url:String = responseDictionary.valueForKey("url") as? String{
                                dispatch_async(dispatch_get_main_queue(),{
                                    comment.updateCommentStatus(QiscusCommentStatus.Sending)
                                    comment.updateCommentText("[file]\(url) [/file]")
                                    print("upload success")
                                    
                                    commentFile.updateURL(url)
                                    commentFile.updateIsUploading(false)
                                    commentFile.updateUploadProgress(1.0)
                                    
                                    self.commentDelegate?.didUploadFile(comment)
                                    self.postComment(comment, file: commentFile, roomId: roomId)
                                })
                            }
                            else if let data:NSDictionary = responseDictionary.valueForKey("results") as? NSDictionary{
                                if let file:NSDictionary = data.valueForKey("file") as? NSDictionary{
                                    if let url:String = file.valueForKey("url") as? String{
                                        dispatch_async(dispatch_get_main_queue(),{
                                            comment.updateCommentStatus(QiscusCommentStatus.Sending)
                                            comment.updateCommentText("[file]\(url) [/file]")
                                            print("upload success")
                                            
                                            commentFile.updateURL(url)
                                            commentFile.updateIsUploading(false)
                                            commentFile.updateUploadProgress(1.0)
                                            
                                            self.commentDelegate?.didUploadFile(comment)
                                            self.postComment(comment, file: commentFile, roomId: roomId)
                                        })
                                    }
                                }
                            }
                        }
                    }
                    upload.progress({ (bytesWritten, totalBytesWritten, totalBytesExpectedToWrite) in //
                        dispatch_async(dispatch_get_main_queue(),{
                            let progress = CGFloat(CGFloat(totalBytesWritten) / CGFloat(totalBytesExpectedToWrite))
                            print("upload progress: ",progress)
                            
                            commentFile.updateIsUploading(true)
                            commentFile.updateUploadProgress(progress)
                            
                            self.commentDelegate?.uploadingFile(comment)
                        })
                    })
                    upload.response(completionHandler: { (request, httpResponse, data, error) in
                        if error != nil || httpResponse?.statusCode >= 400 {
                            comment.updateCommentStatus(QiscusCommentStatus.Failed)
                            commentFile.updateIsUploading(false)
                            commentFile.updateUploadProgress(0)
                            
                            self.commentDelegate?.didFailedUploadFile(comment)
                        }else{
                            print("http response upload: \(httpResponse)\n")
                        }
                    })
                case .Failure(_):
                    print("encoding error:")
                    comment.updateCommentStatus(QiscusCommentStatus.Failed)
                    commentFile.updateIsUploading(false)
                    commentFile.updateUploadProgress(0)
                    self.commentDelegate?.didFailedUploadFile(comment)
                }
            }
        )
    }
    
    // MARK: - Communicate with Server
    public func syncMessage(topicId: Int, triggerDelegate:Bool = false) {
        dispatch_async(dispatch_get_main_queue()) {
            let manager = Alamofire.Manager.sharedInstance
            if let commentId = QiscusComment.getLastSyncCommentId(topicId) {
                let loadURL = QiscusConfig.LOAD_URL
                let parameters:[String: AnyObject] =  [
                        "comment_id"  : commentId,
                        "topic_id" : topicId,
                        "token" : qiscus.config.USER_TOKEN,
                        "after":"true"
                    ]
             
                manager.request(.GET, loadURL, parameters: parameters, encoding: ParameterEncoding.URL, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON { response in
                    print("parameter sync: \(parameters)")
                    print("response sync message: \(response)")
                    if let result = response.result.value {
                        let json = JSON(result)
                        let results = json["results"]
                        let error = json["error"]
                        if results != nil{
                            let comments = json["results"]["comments"].arrayValue
                            if comments.count > 0 {
                                dispatch_async(dispatch_get_main_queue(), {
                                    var newMessageCount: Int = 0
                                    var newComments = [QiscusComment]()
                                    for comment in comments {
                                        
                                        let isSaved = QiscusComment.getCommentFromJSON(comment, topicId: topicId, saved: true)
                                        
                                        if let thisComment = QiscusComment.getCommentById(QiscusComment.getCommentIdFromJSON(comment)){
                                            thisComment.updateCommentStatus(QiscusCommentStatus.Delivered)
                                            if isSaved {
                                                newMessageCount += 1
                                                newComments.insert(thisComment, atIndex: 0)
                                            }
                                        }
                                    }
                                    if newComments.count > 0 {
                                        self.commentDelegate?.gotNewComment(newComments)
                                    }
                                    if triggerDelegate{
                                        let syncData = QSyncNotifData()
                                        syncData.newMessageCount = newMessageCount
                                        syncData.topicId = topicId
                                        self.commentDelegate?.finishedLoadFromAPI(topicId)
                                    }
                                    
                                })
                            }
                        }else if error != nil{
                            if triggerDelegate{
                                self.commentDelegate?.didFailedLoadDataFromAPI("failed to sync message with error \(error)")
                            }
                            print("error sync message: \(error)")
                        }
                    }else{
                        if triggerDelegate{
                            self.commentDelegate?.didFailedLoadDataFromAPI("failed to sync message, connection error")
                        }
                        print("error sync message")
                    }
                }
            }
        }
    }
    
    public func getListComment(topicId topicId: Int, commentId: Int, triggerDelegate:Bool = false, loadMore:Bool = false){ //USED
        let manager = Alamofire.Manager.sharedInstance
        var parameters:[String: AnyObject]? = nil
        var loadURL = ""
//        if QiscusConfig.sharedInstance.requestHeader != nil{
            loadURL = QiscusConfig.LOAD_URL
            parameters =  [
                "last_comment_id"  : commentId,
                "topic_id" : topicId,
                "token" : qiscus.config.USER_TOKEN
            ]
//        }else{
//            loadURL = QiscusConfig.LOAD_URL_(withTopicId: topicId, commentId: commentId)
//        }
        manager.request(.GET, loadURL, parameters: parameters, encoding: ParameterEncoding.URL, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON { response in
            print("response list comment1: \(response)")
            if let result = response.result.value {
                let json = JSON(result)
                let results = json["results"]
                let error = json["error"]
                if results != nil{
                    print("result list comment: \(result)")
                    var newMessageCount: Int = 0
                    let comments = json["results"]["comments"].arrayValue
                    if comments.count > 0 {
                        var newComments = [QiscusComment]()
                        for comment in comments {
                            let isSaved = QiscusComment.getCommentFromJSON(comment, topicId: topicId, saved: true)
                            if let thisComment = QiscusComment.getCommentById(QiscusComment.getCommentIdFromJSON(comment)){
                                thisComment.updateCommentStatus(QiscusCommentStatus.Delivered)
                                if isSaved {
                                    newMessageCount += 1
                                    if loadMore {
                                        newComments.append(thisComment)
                                    }else{
                                        newComments.insert(thisComment, atIndex: 0)
                                    }
                                }
                            }
                        }
                        if newComments.count > 0 {
                            self.commentDelegate?.gotNewComment(newComments)
                        }
                        if loadMore {
                            self.commentDelegate?.didFinishLoadMore()
                        }
                    }
                    if triggerDelegate{
                        self.commentDelegate?.finishedLoadFromAPI(topicId)
                    }
                }else if error != nil{
                    print("error getListComment: \(error)")
                    if triggerDelegate{
                        self.commentDelegate?.didFailedLoadDataFromAPI("failed to load message with error \(error)")
                    }
                }
                
            }else{
                if triggerDelegate {
                    self.commentDelegate?.didFailedLoadDataFromAPI("failed to sync message, connection error")
                }
            }
        }
    }
    
    public func getListComment(withUsers users:[String], triggerDelegate:Bool = false, loadMore:Bool = false){ //USED
        let manager = Alamofire.Manager.sharedInstance
        let loadURL = QiscusConfig.ROOM_REQUEST_URL

        let parameters:[String : AnyObject] =  [
                "emails" : users,
                "token"  : qiscus.config.USER_TOKEN
            ]

        manager.request(.POST, loadURL, parameters: parameters, encoding: ParameterEncoding.URL, headers: QiscusConfig.sharedInstance.requestHeader).responseJSON { response in
            print("parameters: \(parameters)")
            print("url: \(loadURL)")
            print("response list comment: \(response)")
            if let result = response.result.value {
                let json = JSON(result)
                let results = json["results"]
                let error = json["error"]
                if results != nil{
                    print("result list comment2: \(result)")
                    let topicId = json["results"]["room"]["last_topic_id"].intValue
                    QiscusUIConfiguration.sharedInstance.topicId = topicId
                    QiscusChatVC.sharedInstance.topicId = topicId
                    var newMessageCount: Int = 0
                    let comments = json["results"]["comments"].arrayValue
                    if comments.count > 0 {
                        var newComments = [QiscusComment]()
                        for comment in comments {
                            let isSaved = QiscusComment.getCommentFromJSON(comment, topicId: topicId, saved: true)
                            if let thisComment = QiscusComment.getCommentById(QiscusComment.getCommentIdFromJSON(comment)){
                                thisComment.updateCommentStatus(QiscusCommentStatus.Delivered)
                                if isSaved {
                                    newMessageCount += 1
                                    newComments.insert(thisComment, atIndex: 0)
                                }
                            }
                        }
                        if newComments.count > 0 {
                            self.commentDelegate?.gotNewComment(newComments)
                        }
                        if loadMore {
                            self.commentDelegate?.didFinishLoadMore()
                        }
                    }
                    if triggerDelegate{
                        self.commentDelegate?.finishedLoadFromAPI(topicId)
                    }
                }else if error != nil{
                    print("error getListComment: \(error)")
                    if triggerDelegate{
                        self.commentDelegate?.didFailedLoadDataFromAPI("failed to load message with error \(error)")
                    }
                }
                
            }else{
                if triggerDelegate {
                    self.commentDelegate?.didFailedLoadDataFromAPI("failed to sync message, connection error")
                }
            }
        }
    }
    // MARK: - Load More
    public func loadMoreComment(fromCommentId commentId:Int, topicId:Int, limit:Int = 10){
        let comments = QiscusComment.loadMoreComment(fromCommentId: commentId, topicId: topicId, limit: limit)
        print("got \(comments.count) new comments")
        
        if comments.count > 0 {
            var commentData = [QiscusComment]()
            for comment in comments{
                commentData.insert(comment, atIndex: 0)
            }
            print("got \(comments.count) new comments")
            self.commentDelegate?.gotNewComment(commentData)
            self.commentDelegate?.didFinishLoadMore()
        }else{
            self.getListComment(topicId: topicId, commentId: commentId, loadMore: true)
        }
    }
}
