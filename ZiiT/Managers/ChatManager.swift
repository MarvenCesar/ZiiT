//
//  ChatManager.swift
//  ZiiT
//
//  Created by Marven Cesar on 6/5/24.
//
import StreamChat
import StreamChatUI
import Foundation
import UIKit

final class ChatManager{
    static let shared = ChatManager()
    
    private var client: ChatClient!
    
    func setup(){
        let client = ChatClient(config: .init(apiKey: .init("dtb2zae562wu")))
        self.client = client
    }
    // authentication
    func signIn(with username: String, completion: @escaping (Bool)->Void){
        
    }
    func signOut(){
        
    }
    var isSignedIn: Bool{
        return false
    }
    var currentUser: String? {
        return nil
    }
    // channelList + creation
    
    public func createChannelList() -> UIViewController {
        return UIViewController()
    }
    public func createNewChannel(name: String){
        
    }
}
