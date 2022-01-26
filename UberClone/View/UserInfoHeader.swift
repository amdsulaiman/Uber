//
//  UserInfoHeader.swift
//  UberClone
//
//
//

import Foundation
import UIKit

class UserInfoHeader: UIView {
    // MARK: - Properties
    
    private let user: User
    
    private lazy var initialLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 42)
        label.textColor = .white
        label.text = user.firstInitial
        
        return label
    }()
    
    private lazy var profileImageView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.addSubview(initialLabel)
        initialLabel.centerY(inView: view)
        initialLabel.centerX(inView: view)
        
        return view
    }()
    
    private lazy var fullName: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        label.text = user.fullname
        
        return label
    }()
    
    private lazy var emailLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .black
        label.text = user.email
        
        return label
    }()
    
    // MARK: - Lifecycle
    
    init(user: User, frame: CGRect) {
        self.user = user
        super.init(frame: frame)
        
        backgroundColor = .white
        
        addSubview(profileImageView)
        profileImageView.anchor(top: self.safeAreaLayoutGuide.topAnchor, left: leftAnchor, paddingTop: 4, paddingLeft: 12, width: 64, height: 64)
        profileImageView.layer.cornerRadius = 32
        
        let stack = UIStackView(arrangedSubviews: [fullName, emailLabel])
        stack.distribution = .fillEqually
        stack.spacing = 4
        stack.axis = .vertical
        
        addSubview(stack)
        
        stack.centerY(inView: profileImageView, leftAnchor: profileImageView.rightAnchor, paddingLeft: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
