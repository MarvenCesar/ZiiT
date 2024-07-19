//loginViiewController

import UIKit


final class LoginViewController: UIViewController, UITabBarControllerDelegate {
    
    
    // uitextfield
    private let emailField: UITextField = {
        let field = UITextField()
        field.placeholder = "Email..."
        field.keyboardType = .emailAddress
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.leftViewMode = .always
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 50))
        field.translatesAutoresizingMaskIntoConstraints = false
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.placeholder = "Password..."
        field.isSecureTextEntry = true
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.leftViewMode = .always
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 50))
        field.translatesAutoresizingMaskIntoConstraints = false
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGray
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.setTitle("LOGIN", for: .normal)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    private let signUpButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemBlue
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.setTitle("SIGN UP", for: .normal)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    private var isViewVisible = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Decentralized Messaging APP"
        view.backgroundColor = .systemBackground
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(loginButton)
        view.addSubview(signUpButton)
        addConstraints()
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        signUpButton.addTarget(self, action: #selector(didTapSignUp), for: .touchUpInside)
        testEncryptionDecryption()
    }
   
    func testEncryptionDecryption() {
           guard let (publicKey, privateKey) = ChatManager.shared.generateKeyPair(),
                 let symmetricKey = ChatManager.shared.deriveSymmetricKey(publicKey: publicKey, privateKey: privateKey) else {
               print("Key generation or derivation failed")
               return
           }

           let message = "Hey this is a test"
           guard let encryptedData = ChatManager.shared.encryptMessage(message: message, symmetricKey: symmetricKey) else {
               print("Message encryption failed")
               return
           }

           guard let decryptedMessage = ChatManager.shared.decryptMessage(encryptedMessage: encryptedData, symmetricKey: symmetricKey) else {
               print("Message decryption failed")
               return
           }

           print("Original Message: \(message)")
           print("Decrypted Message: \(decryptedMessage)")
       }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        isViewVisible = true
        emailField.becomeFirstResponder()
        
        if ChatManager.shared.isSignedIn {
            presentChatList(animated: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        isViewVisible = false
    }
    
    private func addConstraints() {
        NSLayoutConstraint.activate([
            emailField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            emailField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 50),
            emailField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -50),
            emailField.heightAnchor.constraint(equalToConstant: 50),
            
            passwordField.topAnchor.constraint(equalTo: emailField.bottomAnchor, constant: 20),
            passwordField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 50),
            passwordField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -50),
            passwordField.heightAnchor.constraint(equalToConstant: 50),
            
            loginButton.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 20),
            loginButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 50),
            loginButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -50),
            loginButton.heightAnchor.constraint(equalToConstant: 50),
            
            signUpButton.topAnchor.constraint(equalTo: loginButton.bottomAnchor, constant: 20),
            signUpButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 50),
            signUpButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -50),
            signUpButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func didTapLogin() {
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            showAlert(message: "Please enter both email and password.")
            return
        }
        
        getPassphrase { passphrase in
            ChatManager.shared.signIn(email: email, password: password) { [weak self] success in
                guard success else {
                    self?.showAlert(message: "Login failed. Please try again.")
                    return
                }
                
                guard let userId = ChatManager.shared.currentUser else { return }
                ChatManager.shared.retrieveAndDecryptPrivateKey(userId: userId, passphrase: passphrase) { privateKey in
                    guard let privateKey = privateKey else {
                        self?.showAlert(message: "Failed to retrieve private key.")
                        return
                    }
                    
                    self?.presentChatList()
                }
            }
        }
    }




    @objc private func didTapSignUp() {
        print("SignUp button tapped")
        let signUpVC = SignUpViewController()
        navigationController?.pushViewController(signUpVC, animated: true)
    }
    
    func presentChatList(animated: Bool = true) {
        print("Should show chat list")
        guard let vc = ChatManager.shared.createChannelList() else {
            print("Could not create channel list")
            return
        }
        
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                               target: self,
                                                               action: #selector(didTapCompose))
        let tabVC = TabBarViewController(chatList: vc)
        tabVC.modalPresentationStyle = .fullScreen
        tabVC.delegate = self  // Setting the delegate here
        
        // Ensure the view is in the window hierarchy
        DispatchQueue.main.async {
            if self.isViewVisible {
                print("Presenting TabBarViewController")
                self.present(tabVC, animated: animated)
            } else {
                print("LoginViewController's view is not in the window hierarchy.")
            }
        }
    }
    
    @objc private func didTapCompose() {
        let alert = UIAlertController(title: "New Chat",
                                      message: "Enter Channel Name and Member Emails (comma-separated)",
                                      preferredStyle: .alert)

        alert.addTextField { textField in
            textField.placeholder = "Channel Name"
        }
        alert.addTextField { textField in
            textField.placeholder = "Member Emails"
        }
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Create", style: .default, handler: { [weak self] _ in
            guard let channelName = alert.textFields?.first?.text, !channelName.isEmpty,
                  let emailsString = alert.textFields?.last?.text, !emailsString.isEmpty else {
                return
            }

            let memberEmails = emailsString.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

            DispatchQueue.main.async {
                ChatManager.shared.createNewChannel(name: channelName, memberEmails: memberEmails) { success in
                    DispatchQueue.main.async {
                        if success {
                            print("Channel created successfully")
                            self?.showAlert(title: "Success", message: "Channel created successfully.")
                        } else {
                            print("Failed to create channel")
                            self?.showAlert(title: "Error", message: "Failed to create channel. Please try again.")
                        }
                    }
                }
            }
        }))
        //self.present(alert, animated: true) removed this
       presentedViewController?.present(alert, animated: true)
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }

    
    func attemptAutoLogin(email: String, password: String) {
        print("Attempting auto-login for \(email)")
        ChatManager.shared.signIn(email: email, password: password) { [weak self] success in
            guard success else {
                print("Auto-login failed")
                return
            }
            print("Auto-login successful")
            DispatchQueue.main.async {
                self?.presentChatList()
            }
        }
    }
    
    func getPassphrase(completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "Enter Passphrase", message: "Please enter your passphrase to secure your private key.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Passphrase"
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            if let passphrase = alert.textFields?.first?.text, !passphrase.isEmpty {
                completion(passphrase)
            } else {
                // Handle empty passphrase scenario
                self.showAlert(message: "Passphrase cannot be empty.")
            }
        }
        
        alert.addAction(submitAction)
        present(alert, animated: true)
    }

    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    
}











































































