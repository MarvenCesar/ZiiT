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
    
    // generating tokens manually
    private let tokens = [
        "cesar": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiY2VzYXIifQ.sP0lyM2QD7CkxI9T_wbVgQ82ibBl8jIJ9XmywbGouJ4",
        "david": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiZGF2aWQifQ.EgtPE60wlbo9HVCab7dIOaS5WKD4lx614LkmGEqrMr0"
    
    ]
    
    func setup(){
        let client = ChatClient(config: .init(apiKey: .init("dtb2zae562wu")))
        self.client = client
    }
    // authentication
    func signIn(with username: String, completion: @escaping (Bool)->Void){
        guard !username.isEmpty else {
            completion(false)
            return
        }
        
        guard let token = tokens[username.lowercased()] else {
            completion(false)
            return
        }
        
        client.connectUser(
            userInfo: UserInfo(id: username, name: username),
            token: Token(stringLiteral: token))
        { error in
            completion(error == nil)
            
        }
    }
        
    
    func signOut(){
        client.disconnect()
        client.logout()
        
    }
    var isSignedIn: Bool{
        return client.currentUserId != nil
    }
  var currentUser: String? {
        return client.currentUserId
    }
    // channelList + creation
    
    public func createChannelList() -> UIViewController? {
        guard let id = currentUser else { return nil }
        let list = client.channelListController(query: .init(filter: .containMembers(userIds: [id])))
        let vc = ChatChannelListVC()
        vc.content = list
        list.synchronize()
        return vc
    }
    public func createNewChannel(name: String){
        
    }
}
