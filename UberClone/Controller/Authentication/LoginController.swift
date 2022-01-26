//
//  LoginController.swift
//  UberClone
//
//  
//

import Foundation
import UIKit
import Firebase

class LoginController: UIViewController {
    
    // Mark: - Properties
    
    private let titleLabel : UILabel = {
        let label = UILabel()
        label.text = "UBER"
        label.font = UIFont(name: "Avenir-Light", size: 36)
        label.textColor = UIColor(white: 1, alpha: 0.8)
        return label
    }()
    private lazy var emailcontainerView : UIView = {
        let view =  UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_mail_outline_white_2x"), textField: emailtextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    private lazy var passwordcontainerView : UIView = {
        let view =  UIView().inputContainerView(image: #imageLiteral(resourceName: "ic_lock_outline_white_2x"), textField: passwordtextField)
        view.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return view
    }()
    private let emailtextField : UITextField = {
        return UITextField().textField(withPlaceholder: "Email", isSecureTextEntry: false)
    }()
    
    private let passwordtextField : UITextField = {
        return UITextField().textField(withPlaceholder: "Password", isSecureTextEntry: true)
    }()
    private let loginButton : AuthButton = {
        let button = AuthButton(type: .system)
        button.setTitle("Log In", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        return button
    }()
    let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.lightGray])
        
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.mainBlueTint]))
        
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        button.setAttributedTitle(attributedTitle, for: .normal)
        return button
    }()
    
    // Mark: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
//        emailtextField.text = "Iphone12ProMaxUser@gmail.com"
//        passwordtextField.text = "12345678"
        emailtextField.text = "Iphone12miniDriver@gmail.com"
        passwordtextField.text = "12345678"
        //Iphone12miniDriver@gmail.com
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // Mark: - Selectors
    
    @objc func handleShowSignUp() {
        let controller = SignUpController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    
    @objc func handleLogin(){
        guard let email = emailtextField.text else { return }
        guard let password = passwordtextField.text else { return }
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Failed To Login User with error \(error.localizedDescription)")
                return
            }
          
                print("Successfully logged in user")
            let vc = HomeController()
            currentUserID = Auth.auth().currentUser!.uid
            UserDefaults.standard.setValue(currentUserID, forKey: "UserDefaultsUserID")
            vc.configure()
            vc.modalPresentationStyle = .fullScreen
            self.present(vc, animated: true, completion: nil)
            
           
        }
    }
   
    
    // Mark: - Helper Functions
    
    func configureUI(){
        configureNavigationBar()
        view.backgroundColor = .backgroundColor
        view.addSubview(titleLabel)
        titleLabel.anchor(top:view.safeAreaLayoutGuide.topAnchor)
        titleLabel.centerX(inView: view)
        let stack = UIStackView(arrangedSubviews: [emailcontainerView,passwordcontainerView,loginButton])
        stack.axis  = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 24
        view.addSubview(stack)
        stack.anchor(top: titleLabel.bottomAnchor, left: view.leftAnchor,
                     right: view.rightAnchor, paddingTop: 40, paddingLeft: 16,
                     paddingRight: 16)
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.centerX(inView: view)
        dontHaveAccountButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, height: 32)
    }
    
    func configureNavigationBar(){
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
        
    }
    func signOut(){
        do {
            try Auth.auth().signOut()
        }
        catch let err {
            print("Failed to Sign Out \(err.localizedDescription)")
        }
    }
    
    
}
