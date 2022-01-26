//
//  ContainerController.swift
//  UberClone
//
//  
//

import UIKit
import Firebase


class ContainerController: UIViewController {
    
    // MARK: - Properties
    
    private let homeController = HomeController()
    private var menuController: MenuController!
    private var isExpand = false
    private let backView = UIView()
    private lazy var xOrigin = self.view.frame.width - 80
    private var user: User? {
        didSet {
            guard let user = user else { return }
            homeController.user = user
            configureMenuController(withUser: user)
        }
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        checkIfUserIsLoggedIn()
    }
    
    override var prefersStatusBarHidden: Bool {
        return isExpand
    }
    
    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .slide
    }
    
    // MARK: - Selectors
    
    @objc func dismissMenu() {
        isExpand = false
        animateMenu(shouldExpand: isExpand)
    }
    
    // MARK: - API
    
    func checkIfUserIsLoggedIn() {
        if Auth.auth().currentUser?.uid == nil {
            DispatchQueue.main.async {
                let navigationController = UINavigationController(rootViewController: LoginController())
                navigationController.modalPresentationStyle = .fullScreen
                self.present(navigationController, animated: true, completion: nil)
            }
        } else {
            configure()
        }
    }
    
    func fetchUserData() {
        guard let currentUid = Auth.auth().currentUser?.uid else { return }
        Service.shared.fetchUserData(uid: currentUid) { user in
            self.user = user
        }
    }
    
    // MARK: - Helper Functions
    
    func configure() {
        view.backgroundColor = .backgroundColor
        configureHomeController()
        configureBackView()
        fetchUserData()
    }
    
    func configureHomeController() {
        addChild(homeController)
        homeController.didMove(toParent: self)
        view.addSubview(homeController.view)

        homeController.delegate = self
        homeController.user = user
    }
    
    func configureMenuController(withUser user: User) {
        menuController = MenuController(user: user)
        addChild(menuController)
        menuController.didMove(toParent: self)
        view.insertSubview(menuController.view, at: 0)
    }
    
    func animateMenu(shouldExpand: Bool) {
        if shouldExpand {
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = self.xOrigin
                self.backView.alpha = 1
                self.backView.frame = CGRect(x: self.xOrigin, y: 0, width: 80, height: self.view.frame.height)
            }, completion: nil)
        } else {
            self.backView.alpha = 0
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
                self.homeController.view.frame.origin.x = 0
            }, completion: nil)
        }
        
        animateStatusBar()
    }
    
    func animateStatusBar() {
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0, options: .curveEaseInOut, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        }, completion: nil)

    }
    
    func configureBackView() {
        backView.frame = self.view.bounds
        backView.backgroundColor = UIColor(white: 0, alpha: 0.5)
        backView.alpha = 0
        view.addSubview(backView)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissMenu))
        backView.addGestureRecognizer(tap)
    }
}

// MARK: - HomeControllerDelegate

extension ContainerController: HomeControllerDelegate {
    func handleMenuToggle() {
        print("exe")
        isExpand.toggle()
        animateMenu(shouldExpand: isExpand)
    }
}
