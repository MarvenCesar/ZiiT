import StreamChat
import StreamChatUI
import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

final class ChatManager {
    static let shared = ChatManager()
    
    private var client: ChatClient!
    private let db = Firestore.firestore()
    
    func setup() {
        let client = ChatClient(config: .init(apiKey: .init("dtb2zae562wu")))
        self.client = client
    }
    
    func signUp(email: String, password: String, username: String, completion: @escaping (Bool) -> Void) {
        print("Attempting to sign up user with email: \(email)")
        Auth.auth().createUser(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error during sign-up: \(error.localizedDescription)")
                completion(false)
            } else if let authResult = authResult {
                let user = authResult.user
                print("User signed up successfully: \(user.uid)")
                self.addUsernameToFirestore(userID: user.uid, username: username) { success in
                    completion(success)
                }
            }
        }
    }
    
    func addUsernameToFirestore(userID: String, username: String, completion: @escaping (Bool) -> Void) {
        print("Adding username to Firestore for userID: \(userID)")
        db.collection("users").document(userID).setData([
            "username": username
        ]) { error in
            if let error = error {
                print("Error adding username to Firestore: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Username added to Firestore successfully.")
                completion(true)
            }
        }
    }
    
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) {
        print("Attempting to sign in user with email: \(email)")
        Auth.auth().signIn(withEmail: email, password: password) { authResult, error in
            if let error = error {
                print("Error during sign-in: \(error.localizedDescription)")
                completion(false)
            } else if let authResult = authResult {
                print("User signed in successfully: \(authResult.user.uid)")
                self.connectStreamChat(user: authResult.user, completion: completion)
            }
        }
    }
    
    private func connectStreamChat(user: User, completion: @escaping (Bool) -> Void) {
        print("Attempting to connect Stream Chat for user: \(user.uid)")
        
        let url = URL(string: "https://us-central1-ziit-a9623.cloudfunctions.net/generateStreamToken")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["userId": user.uid]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error fetching token: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            guard let data = data else {
                print("No data received")
                completion(false)
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            let token = json?["token"] as? String ?? ""
            
            if token.isEmpty {
                print("Received empty token")
                completion(false)
                return
            }
            
            print("Received token: \(token)")
            
            self.client.connectUser(
                userInfo: UserInfo(id: user.uid, name: user.email ?? user.uid),
                tokenProvider: { completion in
                    completion(.success(Token(stringLiteral: token)))
                }
            ) { error in
                if let error = error {
                    print("Error connecting to Stream Chat: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("Connected to Stream Chat successfully")
                    completion(true)
                }
            }
        }
        
        task.resume()
    }
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            client.disconnect()
            client.logout()
            print("User signed out successfully")
        } catch let signOutError as NSError {
            print("Error signing out: \(signOutError.localizedDescription)")
        }
    }
    
    var isSignedIn: Bool {
        return Auth.auth().currentUser != nil
    }
    
    var currentUser: String? {
        return Auth.auth().currentUser?.uid
    }
    
    private func fetchUserIDsForNewChannel(excluding currentUserID: String, completion: @escaping ([String]) -> Void) {
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                completion([])
            } else {
                var userIDs: [String] = []
                for document in querySnapshot!.documents {
                    let userID = document.documentID
                    if userID != currentUserID {
                        userIDs.append(userID)
                    }
                }
                print("Fetched user IDs for new channel: \(userIDs)")
                completion(userIDs)
            }
        }
    }
    
    public func createNewChannel(name: String) {
        guard let current = currentUser else {
            return
        }
        fetchUserIDsForNewChannel(excluding: current) { userIDs in
            do {
                let result = try self.client.channelController(
                    createChannelWithId: .init(type: .messaging, id: name),
                    name: name,
                    members: Set(userIDs),
                    isCurrentUserMember: true
                )
                result.synchronize()
                print("New channel created successfully: \(name)")
            } catch {
                print("Error creating new channel: \(error.localizedDescription)")
            }
        }
    }

    public func createChannelList() -> UIViewController? {
        guard let id = currentUser else { return nil }
        let list = client.channelListController(query: .init(filter: .containMembers(userIds: [id])))
        let vc = ChatChannelListVC()
        vc.content = list
        list.synchronize()
        return vc
    }
}




