//
//  LocationTableViewCell.swift
//  UberClone
//
//  
//

import UIKit
import MapKit

class LocationTableViewCell: UITableViewCell {

    // Mark: - Properties
    
    var placemark: MKPlacemark?{
        didSet{
            titleLabel.text = placemark?.name
            addressLabel.text = placemark?.address
        }
    }

    //MARK: - Properites
    
      let  titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    
      let addressLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()
    
    
    // Mark: - LifeCycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        let stack = UIStackView(arrangedSubviews: [titleLabel,addressLabel])
        stack.axis = .vertical
        stack.distribution = .fillEqually
        stack.spacing = 4
        addSubview(stack)
        stack.centerY(inView: self, leftAnchor: leftAnchor,paddingLeft: 12)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
