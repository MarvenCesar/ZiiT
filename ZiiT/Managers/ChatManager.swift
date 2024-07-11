// ChatManager.swift

import StreamChat
import StreamChatUI
import Foundation
import UIKit
import FirebaseAuth
import FirebaseFirestore

//singleton object
final class ChatManager {
    static let shared = ChatManager()
    
    private init() {}
    var client: ChatClient!
    
    private let db = Firestore.firestore()
    
    
    func setup(client: ChatClient) {
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
                self.addUsernameToFirestore(userID: user.uid, email: email, username: username) { success in
                    completion(success)
                }
            }
        }
    }
    
    
    
    func addUsernameToFirestore(userID: String, email: String, username: String, completion: @escaping (Bool) -> Void) {
        print("Adding username and email to Firestore for userID: \(userID)")
        db.collection("users").document(userID).setData([
            "username": username,
            "email": email
        ]) { error in
            if let error = error {
                print("Error adding username and email to Firestore: \(error.localizedDescription)")
                completion(false)
            } else {
                print("Username and email added to Firestore successfully.")
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
        
        guard let url = URL(string: "https://us-central1-ziit-a9623.cloudfunctions.net/generateStreamToken") else {
            print("Invalid URL for token generation")
            completion(false)
            return
        }
        
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
            
            guard let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                  let token = json["token"] as? String, !token.isEmpty else {
                print("Invalid or empty token received")
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
    
    func fetchUsers(completion: @escaping ([String: String]) -> Void) {
        db.collection("users").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error getting documents: \(error.localizedDescription)")
                completion([:])
            } else {
                var users = [String: String]()
                for document in querySnapshot!.documents {
                    let userID = document.documentID
                    let username = document.data()["username"] as? String ?? "Unknown"
                    users[userID] = username
                }
                completion(users)
            }
        }
    }
    
    func fetchCurrentUsername(completion: @escaping (String?) -> Void) {
        guard let userId = currentUser else {
            completion(nil)
            return
        }
        
        let userRef = db.collection("users").document(userId)
        userRef.getDocument { document, error in
            if let error = error {
                print("Error fetching username: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let document = document, document.exists,
                  let data = document.data(),
                  let username = data["username"] as? String else {
                completion(nil)
                return
            }
            
            completion(username)
        }
    }
    
    public func createNewChannel(name: String, memberEmails: [String], completion: @escaping (Bool) -> Void) {
        guard let currentUser = client.currentUserId else {
            print("No current user")
            completion(false)
            return
        }
        // Array to hold member IDs
        var memberIds = [String]()
        
        // Group dispatch to handle multiple async tasks
        let group = DispatchGroup()
        
        for email in memberEmails {
            group.enter()
            fetchUserIDByEmail(email) { userId in
                if let userId = userId {
                    memberIds.append(userId)
                }
                group.leave()
            }
        }
        // After all async tasks are completed
        group.notify(queue: .main) {
            // Ensure the current user is included in the members
            if !memberIds.contains(currentUser) {
                memberIds.append(currentUser)
            }
            do {
                let controller = try self.client.channelController(
                    createChannelWithId: .init(type: .messaging, id: name),
                    name: name,
                    members: Set(memberIds),
                    isCurrentUserMember: true
                )
                controller.synchronize { error in
                    if let error = error {
                        print("Error synchronizing channel: \(error.localizedDescription)")
                        completion(false)
                    } else {
                        print("Channel created successfully")
                        completion(true)
                    }
                }
            } catch {
                print("Error creating channel controller: \(error.localizedDescription)")
                completion(false)
                return
            }
        }
    }

    // Helper function to fetch user ID by email
    func fetchUserIDByEmail(_ email: String, completion: @escaping (String?) -> Void) {
        db.collection("users").whereField("email", isEqualTo: email).getDocuments { querySnapshot, error in
            if let error = error {
                print("Error fetching user document: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let document = querySnapshot?.documents.first else {
                completion(nil)
                return
            }

            let userId = document.documentID
            completion(userId)
        }
    }
    
    func createChannelList() -> UIViewController? {
        guard let id = currentUser else { return nil }
        let query = ChannelListQuery(filter: .containMembers(userIds: [id]))
        let controller = client.channelListController(query: query)
        let vc = ChatChannelListVC()
        vc.content = controller
        controller.synchronize()
        return vc
    }
}




