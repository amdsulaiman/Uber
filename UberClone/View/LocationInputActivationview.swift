//
//  LocationInputActivationview.swift
//  UberClone
//
//  
//

import UIKit

protocol LocationInputViewActionDelegate : AnyObject {
    func presentLocationInputView()
}

class LocationInputActivationview : UIView {
    
    // Mark: - Properties
    
    weak var delegate : LocationInputViewActionDelegate?
    
    private let indicatorView : UIView = {
        let view = UIView()
        view.backgroundColor = .black
        return view
    }()
    private let placeHolderLabel : UILabel = {
        let label = UILabel()
        label.text = "Where to?"
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = .darkGray
        return label
    }()
    
    // Mark: - LifeCycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        
        addSubview(indicatorView)
        indicatorView.centerY(inView: self, leftAnchor: leftAnchor, paddingLeft: 16)
        indicatorView.setDimension(height: 6, width: 6)
        addShadow()
        addSubview(placeHolderLabel)
        placeHolderLabel.centerY(inView: self, leftAnchor: indicatorView.rightAnchor, paddingLeft: 20)
        indicatorView.setDimension(height: 6, width: 6)
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleShowLocationInputView))
        addGestureRecognizer(tap)
        
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Mark: - Selectors
    
    @objc func handleShowLocationInputView(){
        delegate?.presentLocationInputView()
    }
    
}
