//
//  QiscusTextConfiguration.swift
//  Example
//
//  Created by Ahmad Athaullah on 9/7/16.
//  Copyright © 2016 Ahmad Athaullah. All rights reserved.
//

import UIKit

public class QiscusTextConfiguration: NSObject {
    static var sharedInstance = QiscusTextConfiguration()
    
    /// Your text to show as subtitle if there isn't any message, Default value : "Let's write message to start conversation"
    public var emptyMessage = "Let's write message to start conversation"
    
    /// Your text to show as title if there isn't any message, Default value : "Welcome"
    public var emptyTitle = "Welcome"
    
    /// Your text to show as title chat, Default value : "Title"
    public var chatTitle = "Title"
    
    /// Your text to show as subtitle chat, Default value : "Sub Title"
    public var chatSubtitle = "Sub Title"
    
    /// Your text if you set chat read only, Default value : "Archieved message: This message was locked. Click the key to open the conversation."
    public var readOnlyText = "Archieved message: This message was locked. Click the key to open the conversation."
    
    /// Your text placeholder if you want to send any message, Default value : "Text a message here ..."
    public var textPlaceholder = "Text a message here ..."
    
    /// Your text to show as title alert when you access gallery but you not allow gallery access, Default value : "Important"
    public var galeryAccessAlertTitle = "Important"
    
    /// Your text to show as content alert when you access gallery but you not allow gallery access, Default value : "We need photos access to upload image.\nPlease allow photos access in your iPhone Setting"
    public var galeryAccessAlertText = "We need photos access to upload image.\nPlease allow photos access in your iPhone Setting"
    
    /// Your text to show as title confirmation when you want to upload image/file, Default value : "CONFIRMATION"
    public var confirmationTitle = "CONFIRMATION"
    
    /// Your text to show as content confirmation when you want to upload image, Default value : "Are you sure to send this image?"
    public var confirmationImageUploadText = "Are you sure to send this image?"
    
    /// Your text to show as content confirmation when you want to upload file, Default value : "Are you sure to send"
    public var confirmationFileUploadText = "Are you sure to send"
    
    /// Your text in back action, Default value : "Back"
    public var backText = "Back"
    
    /// Your question mark, Default value : "?"
    public var questionMark = "?"
    
    /// Your text in alert OK button, Default value : "OK"
    public var alertOkText = "OK"
    
    /// Your text in alert Cancel button, Default value : "CANCEL"
    public var alertCancelText = "CANCEL"
    
    /// Your text in alert Setting button, Default value : "SETTING"
    public var alertSettingText = "SETTING"
    
    /// Your text if the day is "today", Default value : "Today"
    public var todayText = "Today"
    
    /// Your text if it is the process of uploading file, Default value : "Uploading"
    public var uploadingText = "Uploading"
    
    /// Your text if it is the process of uploading image, Default value : "Sending"
    public var sendingText = "Sending"
    
    /// Your text if the process of uploading fail, Default value : "Sending Failed"
    public var failedText = "Sending Failed"
    
    /// Your text if there isn't connection internet, Default value :  "can't connect to internet, please check your connection"
    public var noConnectionText = "can't connect to internet, please check your connection"
    
    private override init(){}
}
