import UIKit

protocol SignUpViewControllerDelegate: AnyObject {
    func signUpViewControllerDidCompleteSignUp(_ controller: SignUpViewController, email: String, password: String)
}

final class SignUpViewController: UIViewController {
    weak var delegate: SignUpViewControllerDelegate?

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
        view.addSubview(emailField)
        view.addSubview(passwordField)
        view.addSubview(usernameField)
        view.addSubview(signUpButton)
        addConstraints()
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
        print("SignUp button tapped")
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        usernameField.resignFirstResponder()
        
        guard let email = emailField.text, !email.isEmpty,
              let password = passwordField.text, !password.isEmpty,
              let username = usernameField.text, !username.isEmpty else {
            print("Missing field data")
            return
        }
        
        print("Starting sign-up process for \(email)")
        
        ChatManager.shared.signUp(email: email, password: password, username: username) { [weak self] success in
            print("Sign-up completion handler called")
            guard success else {
                print("Sign-up failed")
                return
            }
            print("User signed up successfully")
            
            DispatchQueue.main.async {
                self?.delegate?.signUpViewControllerDidCompleteSignUp(self!, email: email, password: password)
                self?.navigationController?.popViewController(animated: true)
            }
        }
    }
}









