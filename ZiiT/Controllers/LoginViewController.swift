import UIKit

final class LoginViewController: UIViewController, SignUpViewControllerDelegate {
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "ZiiT"
        view.backgroundColor = .systemBackground
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(loginButton)
        view.addSubview(signUpButton)
        addConstraints()
        loginButton.addTarget(self, action: #selector(didTapLogin), for: .touchUpInside)
        signUpButton.addTarget(self, action: #selector(didTapSignUp), for: .touchUpInside)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        emailField.becomeFirstResponder()
        
        if ChatManager.shared.isSignedIn {
            presentChatList(animated: false)
        }
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
        print("Login button tapped")
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty else {
            print("Missing field data")
            return
        }
        
        print("Starting login process for \(email)")
        
        ChatManager.shared.signIn(email: email, password: password) { [weak self] success in
            guard success else {
                print("Login failed")
                return
            }
            print("User logged in successfully")
            DispatchQueue.main.async {
                self?.presentChatList()
            }
        }
    }
    
    @objc private func didTapSignUp() {
        print("SignUp button tapped")
        let signUpVC = SignUpViewController()
        signUpVC.delegate = self
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

        // Ensure the view is in the window hierarchy
        DispatchQueue.main.async {
            if self.view.window != nil {
                print("Presenting TabBarViewController")
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
    
    // Delegate method
    func signUpViewControllerDidCompleteSignUp(_ controller: SignUpViewController, email: String, password: String) {
        attemptAutoLogin(email: email, password: password)
    }
}






