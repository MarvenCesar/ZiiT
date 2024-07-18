// SignUpViewController

import UIKit
import Foundation
import FirebaseAuth

final class SignUpViewController: UIViewController {
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
        title = "Sign Up"
        view.backgroundColor = .systemBackground
        setupUI()
        setupActions()
    }
    
    private func setupUI() {
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(usernameField)
        view.addSubview(signUpButton)
        addConstraints()
    }
    
    private func setupActions() {
        signUpButton.addTarget(self, action: #selector(didTapSignUp), for: .touchUpInside)
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
            
            usernameField.topAnchor.constraint(equalTo: passwordField.bottomAnchor, constant: 20),
            usernameField.leftAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leftAnchor, constant: 50),
            usernameField.rightAnchor.constraint(equalTo: view.safeAreaLayoutGuide.rightAnchor, constant: -50),
            usernameField.heightAnchor.constraint(equalToConstant: 50),
            
            signUpButton.topAnchor.constraint(equalTo: usernameField.bottomAnchor, constant: 20),
            signUpButton.leftAnchor.constraint(equalTo: view.leftAnchor, constant: 50),
            signUpButton.rightAnchor.constraint(equalTo: view.rightAnchor, constant: -50),
            signUpButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    @objc private func didTapSignUp() {
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        usernameField.resignFirstResponder()
        
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let username = usernameField.text, !username.isEmpty else {
            showAlert(message: "Please fill in all fields.")
            return
        }
        
        promptForPassphrase { passphrase in
            ChatManager.shared.signUp(email: email, password: password, username: username) { [weak self] success in
                guard success else {
                    self?.showAlert(message: "Sign-up failed. Please try again.")
                    return
                }
                
                // Generate key pair
                guard let (publicKey, privateKey) = ChatManager.shared.generateKeyPair() else { return }
                
                // Encrypt and store private key
                ChatManager.shared.encryptAndStorePrivateKey(privateKey, passphrase: passphrase, userId: Auth.auth().currentUser!.uid)
                
                // Save public key in Firestore
                ChatManager.shared.savePublicKey(userId: Auth.auth().currentUser!.uid, publicKey: publicKey)
                
                DispatchQueue.main.async {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    func promptForPassphrase(completion: @escaping (String) -> Void) {
        let alert = UIAlertController(title: "Create Passphrase", message: "Enter a passphrase to secure your private key.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            textField.isSecureTextEntry = true
            textField.placeholder = "Passphrase"
        }
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { _ in
            if let passphrase = alert.textFields?.first?.text, !passphrase.isEmpty {
                completion(passphrase)
            } else {
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
