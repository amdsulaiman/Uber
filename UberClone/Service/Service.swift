//
//  Service.swift
//  UberClone
//
//  
//

import Firebase
import CoreLocation
import GeoFire

let DB_REF = Database.database().reference()
let REF_USERS =  DB_REF.child("users")
let REF_DRIVER_LOCATIONS = DB_REF.child("driver-locations")
let REF_TRIPS = DB_REF.child("trips")

struct DriverService {
    static let shared = DriverService()
    func observeTrips(completion : @escaping(Trip) -> Void ){
        REF_TRIPS.observe(.childAdded) { (snapshot) in
            guard let dictionary = snapshot.value as? [String:Any] else { return }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
    }
    func acceptTrip(trip:Trip, completion:@escaping(Error? , DatabaseReference) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let values = ["driverUid" : uid,
        "state" : TripState.accepted.rawValue] as [String:Any]
        REF_TRIPS.child(trip.passengerUid).updateChildValues(values, withCompletionBlock: completion)
    }
    func observeTripCancel(trip: Trip, completion: @escaping() -> Void) {
        REF_TRIPS.child(trip.passengerUid).observeSingleEvent(of: .childRemoved) { _ in
            completion()
        }
    }
    func updateDriverLocation(location : CLLocation) {
        print("Updated")
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let geofire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        geofire.setLocation(location, forKey: uid)
    }
    func updateTripState(trip: Trip, state: TripState, completion: @escaping(Error?, DatabaseReference) -> Void) {
        REF_TRIPS.child(trip.passengerUid).child("state").setValue(state.rawValue, withCompletionBlock: completion)
        
        if state == .completed {
            REF_TRIPS.child(trip.passengerUid).removeAllObservers()
        }
    }
}
struct PassengerService {
    static let shared = PassengerService()
    func fetchDrivers(with location : CLLocation, completion:@escaping(User) -> Void){
        let geoFire = GeoFire(firebaseRef: REF_DRIVER_LOCATIONS)
        
        REF_DRIVER_LOCATIONS.observe(.value) { (snapshot) in
            geoFire.query(at: location, withRadius: 50).observe(.keyEntered, with: { (uid, location) in
                Service.shared.fetchUserData(uid: uid) { (user) in
                    var driver = user
                    driver.location = location
                    driver.location = location
                    completion(driver)
                }
            })
        }
        
    }
    func uploadTrip(_ pickupCoordinates: CLLocationCoordinate2D, _ destinationCoordinates: CLLocationCoordinate2D, completion: @escaping(Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        let pickupArray = [pickupCoordinates.latitude, pickupCoordinates.longitude]
        let destinationArray = [destinationCoordinates.latitude, destinationCoordinates.longitude]
        
        let values = [
            "pickupCoordinates": pickupArray,
            "destinationCoordinates": destinationArray,
            "state": TripState.requested.rawValue
        ] as [String: Any]
        
        REF_TRIPS.child(uid).updateChildValues(values, withCompletionBlock: completion)
    }
   
    
    
    func observeCurrentTrip(completion:@escaping(Trip) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        REF_TRIPS.child(uid).observe(.value) { (snapshot) in
            guard let dictionary = snapshot.value as? [String:Any] else { return }
            let uid = snapshot.key
            let trip = Trip(passengerUid: uid, dictionary: dictionary)
            completion(trip)
        }
        
    }
    func deleteTrip(completion:@escaping(Error? , DatabaseReference) -> Void){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        REF_TRIPS.child(uid).removeValue(completionBlock: completion)
    }
    func saveLocation(locationString: String, type: LocationType, completion: @escaping (Error?, DatabaseReference) -> Void) {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let key: String = type == .home ? "homeLocation" : "workLocation"
        REF_USERS.child(uid).child(key).setValue(locationString, withCompletionBlock: completion)
    }
}

struct Service {
    static let shared = Service()
    
    func fetchUserData(uid:String,completion : @escaping(User) -> Void){
        guard let currentUId = Auth.auth().currentUser?.uid else { return }
        REF_USERS.child(currentUId).observeSingleEvent(of: .value) { (snapshot) in
            let uid = snapshot.key
            guard let dictionary = snapshot.value as? [String:Any] else { return }
            let user = User(uid: uid, dictionary: dictionary)
            print(user)
            completion(user)
        }
    }
  

        
    
}
  
