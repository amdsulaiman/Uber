//
//  User.swift
//  UberClone
//
//  
//
import CoreLocation
enum AccountType: Int {
    case passenger
    case driver
}

struct  User {
    let fullname : String
    let email : String
    let accountType: Int
    var location : CLLocation?
    var uid : String
    var homeLocation: String?
    var workLocation: String?
    var firstInitial: String { return String(fullname.prefix(1)) }
    
    init(uid:String,dictionary:[String:Any]) {
        self.uid = uid
        self.fullname = dictionary["fullname"] as? String ?? ""
        self.email = dictionary["email"] as? String ?? ""
        
        if let home = dictionary["homeLocation"] as? String {
            self.homeLocation = home
        }
        
        if let work = dictionary["workLocation"] as? String {
            self.workLocation = work
        }
        self.accountType = dictionary["accountType"] as? Int ?? 0
        
    }
}
