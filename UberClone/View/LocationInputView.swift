//
//  LocationInputView.swift
//  UberClone
//
//  
//

import UIKit

protocol LocationInputViewDelegate : AnyObject {
    func dismissLocationInputActionView()
    func executeSearch(query:String)
}

class LocationInputView: UIView {
 
    // Mark: - Properties
    
     var user : User? {
        didSet{
            titleLabel.text = user?.fullname
        }
    }
    
    weak var delegate : LocationInputViewDelegate?
    private let backButton : UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp-1").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleBackTapped), for: .touchUpInside)
        return button
    }()
     let titleLabel : UILabel = {
        let label = UILabel()
        label.text = ""
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .darkGray
        return label
    }()
    private let startLocationIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    private let linkingView: UIView = {
        let view = UIView()
        view.backgroundColor = .darkGray
        return view
    }()
    private  let destinationIndicatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    lazy var startingLocationTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Current Location"
        tf.backgroundColor = .groupTableViewBackground
        tf.isEnabled = false
        tf.font = UIFont.systemFont(ofSize: 14)
        let paddingView = UIView()
        paddingView.setDimension(height: 30, width: 8)
        tf.leftView = paddingView
        tf.leftViewMode = .always
                
        return tf
    }()
    
    lazy var destinationTextField: UITextField = {
        let tf = UITextField()
        tf.placeholder = "Enter a destination.."
        tf.backgroundColor = UIColor.rgb(red: 215, green: 215, blue: 215)
        tf.returnKeyType = .search
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.clearButtonMode = .whileEditing
        let paddingView = UIView()
        paddingView.setDimension(height: 30, width: 8)
        tf.leftView = paddingView
        tf.leftViewMode = .always
        tf.delegate = self
        tf.clearButtonMode = .whileEditing
        return tf
    }()
    
    
    // Mark: - LifeCycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addShadow()
        backgroundColor = .white
        addSubview(backButton)
        backButton.anchor(top:topAnchor, left: leftAnchor,paddingTop: 44,
                          paddingLeft: 12,width: 24,height: 25)
        addSubview(titleLabel)
        titleLabel.centerY(inView: backButton)
        titleLabel.centerX(inView: self)
        addSubview(startingLocationTextField)
        startingLocationTextField.anchor(top: backButton.bottomAnchor, left: leftAnchor, right: rightAnchor,
                                         paddingTop: 4, paddingLeft: 40, paddingRight: 40, height: 30)
        
        addSubview(startLocationIndicatorView)
        startLocationIndicatorView.centerY(inView: startingLocationTextField, leftAnchor: leftAnchor, paddingLeft: 20)
        startLocationIndicatorView.setDimension(height: 6, width: 6)
        startLocationIndicatorView.layer.cornerRadius = 6 / 2
        
        addSubview(destinationTextField)
        destinationTextField.anchor(top: startingLocationTextField.bottomAnchor, left: leftAnchor,
                                    right: rightAnchor, paddingTop: 12, paddingLeft: 40,
                                    paddingRight: 40,height: 30)
        
        addSubview(destinationIndicatorView)
        destinationIndicatorView.centerY(inView: destinationTextField, leftAnchor: leftAnchor, paddingLeft: 20)
        destinationIndicatorView.setDimension(height: 6, width: 6)
        
        addSubview(linkingView)
        linkingView.anchor(top: startLocationIndicatorView.bottomAnchor,
                           bottom: destinationIndicatorView.topAnchor, paddingTop: 4,
                           paddingLeft: 0, paddingBottom: 4, width: 0.5)
        linkingView.centerX(inView: startLocationIndicatorView)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // Mark: - Selectors
    
    @objc func handleBackTapped(){
        delegate?.dismissLocationInputActionView()
    }
    
}
extension LocationInputView : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let query = textField.text else { return false }
        delegate?.executeSearch(query: query)
        return true
    }
}
