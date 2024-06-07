//
//  ViewController.swift
//  ZiiT
//
//  Created by Marven Cesar on 6/3/24.
//

import UIKit

/*
 - Login Screen
 - Channel List, Dms Group Chat
 - message, create chat,channels
 - settings
 - test
 */
final class LoginViewController: UIViewController {
    private let usernameField: UITextField = {
        let field = UITextField()
        field.placeholder = "Username..."
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.leftViewMode = .always
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 50))
        field.translatesAutoresizingMaskIntoConstraints = false
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    // Login button
    private let button: UIButton = {
        let button = UIButton()
        button.backgroundColor = .systemGray
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitleColor(.white, for: .normal)
        button.setTitle("CONTINUE", for: .normal)
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ZiiT"
        view.backgroundColor = .systemBackground
        view.addSubview(usernameField)
        view.addSubview(button)
        addConstraints()
        button.addTarget(self, action: #selector(didTapContinue), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        usernameField.becomeFirstResponder()
        
        if ChatManager.shared.isSignedIn {
            presentChatList(animated: false)
        }
    }

    private func addConstraints() {
        NSLayoutConstraint.activate([
            usernameField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 50),
            usernameField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 50),
            usernameField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -50),
            usernameField.heightAnchor.constraint(equalToConstant: 50),
            
            button.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 20),
            button.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 50),
            button.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -50),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func didTapContinue() {
        usernameField.resignFirstResponder()
        guard let text = usernameField.text, !text.isEmpty else {
            return
        }
        
        ChatManager.shared.signIn(with: text) { [weak self] success in
            guard success else {
                // Handle the error here, maybe show an alert to the user
                return
            }
            print("Did Login")
            DispatchQueue.main.async {
                self?.presentChatList()
            }
        }
    }
    
    private func presentChatList(animated: Bool = true) {
        print("Should Show Chat List")
        guard let vc = ChatManager.shared.createChannelList() else { return }
        
        vc.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .compose,
                                                               target: self,
                                                               action: #selector(didTapCompose))
        let tabVC = TabBarViewController(chatList: vc)
        tabVC.modalPresentationStyle = .fullScreen

        // Ensure the view is in the window hierarchy
        DispatchQueue.main.async {
            if self.view.window != nil {
                self.present(tabVC, animated: animated)
            } else {
                print("LoginViewController's view is not in the window hierarchy.")
            }
        }
    }
    
    @objc private func didTapCompose() {
        let alert = UIAlertController(title: "New Chat",
                                      message: "Enter channel name",
                                      preferredStyle: .alert)
        alert.addTextField()
        alert.addAction(.init(title: "Cancel", style: .cancel))
        alert.addAction(.init(title: "Create", style: .default, handler: { _ in
            guard let text = alert.textFields?.first?.text, !text.isEmpty else {
                return
            }
            ChatManager.shared.createNewChannel(name: text)
        }))
        
        presentedViewController?.present(alert, animated: true)
    }
}


