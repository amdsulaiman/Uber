//
//  MenuController.swift
//  UberClone
//
//  
//


import UIKit
import Firebase

enum MenuOptions: Int, CaseIterable, CustomStringConvertible {
    case yourTrips
    case settings
    case logout
    
    var description: String {
        switch self {
        case .yourTrips: return "Your Trips"
        case .settings: return "Settings"
        case .logout: return "Log Out"
        }
    }
}

class MenuController: UIViewController {
    
    // MARK: - Properties
    
    private let user: User
    
    private lazy var menuHeader: MenuHeader = {
        let frame = CGRect(x: 0, y: 0, width: self.view.frame.width - 80, height: 140)
        let view = MenuHeader(user: user, frame: frame)
        
        return view
    }()
    
    private let menuItem1: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.black, for: .normal)
        let attributedTitle = NSMutableAttributedString(string: MenuOptions.yourTrips.description, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .medium)])
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        
        return button
    }()
    
    private let menuItem2: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.black, for: .normal)
        let attributedTitle = NSMutableAttributedString(string: MenuOptions.settings.description, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .medium)])
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        return button
    }()
    
    private let menuItem3: UIButton = {
        let button = UIButton(type: .system)
        button.setTitleColor(.black, for: .normal)
        let attributedTitle = NSMutableAttributedString(string: MenuOptions.logout.description, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20, weight: .medium)])
        
        button.setAttributedTitle(attributedTitle, for: .normal)
        
        return button
    }()
    
    // MARK: - Lifecycle
    
    init(user: User) {
        self.user = user
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureUI()
    }
    
    // MARK: - Selectors
    
    @objc func yourTripButtonHandler() {
        
    }
    
    @objc func settingButtonHandler() {
        let controller = SettingsController(user: user)
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        
        present(nav, animated: true, completion: nil)
    }
    
    @objc func logoutButtonHandler() {
        let alert = UIAlertController(title: nil, message: "Are you sure you want to log out?", preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { _ in
            self.signOut()
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        self.present(alert, animated: true, completion: nil)
    }
    
    // MARK: - API
    
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                let navigationController = UINavigationController(rootViewController: LoginController())
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)
            }
        } catch {
            print("DEBUG: Error signing out")
        }
    }
    
    // MARK: - Helper Functions
    
    func configureUI() {
        view.backgroundColor = .white
        view.addSubview(menuHeader)
        view.addSubview(menuItem1)
        menuItem1.anchor(top: menuHeader.bottomAnchor, left: view.leftAnchor, paddingTop: 21, paddingLeft: 15)
        menuItem1.addTarget(self, action: #selector(yourTripButtonHandler), for: .touchUpInside)
        
        view.addSubview(menuItem2)
        menuItem2.anchor(top: menuItem1.bottomAnchor, left: view.leftAnchor, paddingTop: 21, paddingLeft: 15)
        menuItem2.addTarget(self, action: #selector(settingButtonHandler), for: .touchUpInside)
        
        view.addSubview(menuItem3)
        menuItem3.anchor(top: menuItem2.bottomAnchor, left: view.leftAnchor, paddingTop: 21, paddingLeft: 15)
        menuItem3.addTarget(self, action: #selector(logoutButtonHandler), for: .touchUpInside)
    }
}
