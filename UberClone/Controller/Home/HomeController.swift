//
//  HomeController.swift
//  UberClone
//
//  
//

import UIKit
import Firebase
import MapKit
import UserNotifications


private let reuseIdentifier = "LocationCell"
private let annotationIdentifier = "DriverAnnotation"
var currentUserID : String = ""

private enum ActionButtonConfiguration {
    case showMenu
    case dismissActionView
    
    init() {
        self = .showMenu
    }
}
private enum AnnotationType: String {
    case pickup
    case destination
}
protocol HomeControllerDelegate: AnyObject {
    func handleMenuToggle()
}

class HomeController: UIViewController {

    // Mark: - Properties
    
    private let mapView = MKMapView()
    private let locationManager = LocationHandler.shared.locationManager
    private let inputActivationView = LocationInputActivationview()
    private let locationInputView = LocationInputView()
    private let rideActionView = RideActionView()
    private let tableView = UITableView()
    private var searchResults  = [MKPlacemark]()
    private var savedLocations = [MKPlacemark]()
    private final  let locationInputViewHeight : CGFloat = 200
    private final  let rideActionViewHeight : CGFloat = 300
    private var actionButtonConfig = ActionButtonConfiguration()
    private var route : MKRoute?
    weak var delegate: HomeControllerDelegate?
    let notificationCenter = UNUserNotificationCenter.current()
     var user : User? {
        didSet{
            locationInputView.user = user
            if user?.accountType == 0{
                print("I am a Pasenger")
                fetchDrivers()
                configureLocationInputActivationView()
                configureSavedUserLocations()
                observeCurrentTrip()
            }
            else {
                print("I am a Driver")
                observeTrips()
                observeCurrentTrip()
            }
        }
    }
    private var trip : Trip? {
        didSet {
            guard let user = user else { return }
            if user.accountType == 1 {
                guard let trip = trip else { return }
                    let controller = PickupController(trip: trip)
                    controller.modalPresentationStyle = .fullScreen
                    controller.delegate = self
                    sendNotification()
                    self.present(controller, animated: true, completion: nil)
            }
            else {
                print("DEBUG:SHOW RIDE ACTION VIEW FOR ACCEPTED TRIP")
            }
            
            
        }
        
    }
    private let actionButton : UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(actionButtonPressed), for: .touchUpInside)
        return button
    }()
        
    
    // Mark: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("User acc type is \(user?.accountType)")
        print("Location is ....\(locationManager?.location)")
        enableLocationService()
        configureUI()
        configureRideActionView()
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) {
            (permissionGranted, error) in
            if(!permissionGranted)
            {
                print("Permission Denied")
            }
        }
        
        
    
    }
    func sendNotification(){
       
            let content = UNMutableNotificationContent()
            content.title = "Uber"
            content.body = "Trip Request"
            content.sound = UNNotificationSound.init(named:UNNotificationSoundName(rawValue: "Uber Ringtone.mp3"))
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            self.notificationCenter.add(request) { (error) in
                if(error != nil)
                {
                    print("Error " + error.debugDescription)
                    return
                }
            }
    }
    
    
    // Mark: - Helper Functions
    
    //Mark API
    
    func startTrip(){
        guard let trip = self.trip else { return }
        DriverService.shared.updateTripState(trip: trip, state: .inProgress) { err, ref in
            self.rideActionView.config = .tripInProgress
            self.removeAnnotationsAndOverlays()
            self.mapView.addAnnotationAndSelect(forCoordinate: trip.destinationCoordinates)
            
            let placemark = MKPlacemark(coordinate: trip.destinationCoordinates)
            let mapItem = MKMapItem(placemark: placemark)
            
            self.setCustomRegion(withType: .destination, coordinates: trip.destinationCoordinates)
            self.generatePolyline(toDestination: mapItem)
            
            self.mapView.zoomToFit(annotations: self.mapView.annotations)
        }
    }
    
    
    func fetchUserData(){
        guard let currentUId = Auth.auth().currentUser?.uid else { return}
        Service.shared.fetchUserData(uid: currentUId) { (user) in
            self.user = user
        }
    }
    func fetchDrivers(){
        guard let location = locationManager?.location else { return }
        PassengerService.shared.fetchDrivers(with: location) { (driver) in
            guard let coordinate = driver.location?.coordinate else { return }
            let annotation = DriverAnnotation(uid: driver.uid, coordinate: coordinate)
            var driverIsVisible: Bool {
                return self.mapView.annotations.contains(where: { annotation -> Bool in
                    guard let driverAnno = annotation as? DriverAnnotation else { return false }
                    if driverAnno.uid == driver.uid {
                        driverAnno.updateAnnotationPosition(withCoordinate: coordinate)
                       // self.zoomForActiveTrip(withDriverUid: driver.uid)
                        return true
                    }
                    return false
                })
            }
            
            if !driverIsVisible {
                self.mapView.addAnnotation(annotation)
            }
           
            
        }
    }
    func observeTrips(){
        DriverService.shared.observeTrips { trip in
            self.trip = trip
        }
    }

    func observeCurrentTrip() {
        PassengerService.shared.observeCurrentTrip { trip in
            self.trip = trip
            
            guard let state = trip.state else { return }
            guard let driverUid = trip.driverUid else { return }
            
            switch state {
            case .requested:
                break
            case .accepted:
                self.shouldPresentLoadingView(false)
                self.removeAnnotationsAndOverlays()
                self.zoomForActiveTrip(withDriverUid: driverUid)
                
                Service.shared.fetchUserData(uid: driverUid) { driver in
                    self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: driver)
                }
            case .driverArrived:
                self.rideActionView.config = .driverArrived
            case .inProgress:
                self.rideActionView.config = .tripInProgress
            case .arrivedAtDestination:
                self.rideActionView.config = .endTrip
            case .completed:
                PassengerService.shared.deleteTrip { (error, ref) in
                    self.animateRideActionView(shouldShow: false)
                    self.centerMapOnUserLocation()
                    self.configureActionButton(config: .showMenu)
                    self.inputActivationView.alpha = 1
                    if self.user?.accountType == 1 {
                        self.presentAlertController(withTitle:"Trip Completed", message: "We hope you enjoyed your trip")
                    }
                    else if self.user?.accountType == 0 {
                        self.presentAlertController(withTitle:"Trip Completed", message: "We hope you enjoyed your trip")
                    }
                   
                }

            case .denied:
                self.shouldPresentLoadingView(false)
                self.presentAlertController(withTitle: "Oops",
                                            message: "It looks like we couldnt find you a driver. Please try again..")
                PassengerService.shared.deleteTrip { (err, ref) in
                    self.centerMapOnUserLocation()
                    self.configureActionButton(config: .showMenu)
                    self.inputActivationView.alpha = 1
                    self.removeAnnotationsAndOverlays()
                }
            }
        }
    }
    

    func signOut(){
        do {
             try Auth.auth().signOut()
            DispatchQueue.main.async {
                let nav = UINavigationController(rootViewController: LoginController())
                self.present(nav, animated: true, completion: nil)
            }
        }
        catch let err {
            print("Failed to Sign Out \(err.localizedDescription)")
        }
    }
    func configureNavigationBar(){
        navigationController?.navigationBar.isHidden = true
        navigationController?.navigationBar.barStyle = .black
    }
    func configureUI() {
        fetchUserData()
        configureNavigationBar()
        configureMapView()
        view.addSubview(inputActivationView)
        view.addSubview(actionButton)
        actionButton.anchor(top:view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,paddingTop: 16, paddingLeft: 16, width: 30, height: 30)
        configureTableView()
    }
    func configureLocationInputActivationView() {
        view.addSubview(inputActivationView)
        inputActivationView.centerX(inView: view)
        inputActivationView.setDimension(height: 50, width: view.frame.width - 64)
        inputActivationView.anchor(top: actionButton.bottomAnchor, paddingTop: 32)
        inputActivationView.alpha = 0
        inputActivationView.delegate = self
        
        UIView.animate(withDuration: 2) {
            self.inputActivationView.alpha = 1
        }
    }
    func configureMapView(){
        view.addSubview(mapView)
        mapView.frame = view.frame
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.delegate = self
        
    }
    func configureLocationViewInput() {
        locationInputView.delegate = self
        view.addSubview(locationInputView)
        locationInputView.anchor(top: view.topAnchor, left: view.leftAnchor,
                                 right: view.rightAnchor, height: locationInputViewHeight)
        locationInputView.alpha = 0
        
        UIView.animate(withDuration: 0.5, animations: {
            self.locationInputView.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, animations: {
                self.tableView.frame.origin.y = self.locationInputViewHeight 
            })
        }
    }
    func configureTableView(){
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        tableView.register(LocationTableViewCell.self, forCellReuseIdentifier: reuseIdentifier)
        let height = view.frame.height - locationInputViewHeight
        tableView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: height)
        view.addSubview(tableView)
        
    }
    func configure() {
  
    }
    func dismissLocationView(completion : ((Bool) -> Void)? = nil) {
        UIView.animate(withDuration: 0.5, animations: {
            self.locationInputView.alpha = 0
            self.tableView.frame.origin.y = self.view.frame.height
            self.locationInputView.removeFromSuperview()
        }, completion: completion)
        
    }
    fileprivate func configureActionButton(config: ActionButtonConfiguration) {
        switch config {
        case .showMenu:
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
        case .dismissActionView:
            actionButton.setImage(#imageLiteral(resourceName: "baseline_arrow_back_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            actionButtonConfig = .dismissActionView
        }
    }
    func configureSavedUserLocations() {
        guard let user = user else { return }
        savedLocations.removeAll()
        
        if let homeLocation = user.homeLocation {
            geocodeAddressString(address: homeLocation)
        }
        
        if let workLocation = user.workLocation {
            geocodeAddressString(address: workLocation)
        }
    }
    
    func geocodeAddressString(address: String) {
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(address) { (placemarks, error) in
            guard let clPlacemark = placemarks?.first else { return }
            let placemark = MKPlacemark(placemark: clPlacemark)
            self.savedLocations.append(placemark)
            self.tableView.reloadData()
        }
    }
    
    @objc func actionButtonPressed(){
        switch actionButtonConfig {
        case .showMenu:
            delegate?.handleMenuToggle()
        case  .dismissActionView :
            self.tableView.reloadData()
           removeAnnotationsAndOverlays()
            mapView.showAnnotations(mapView.annotations, animated: true)
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
                self.configureActionButton(config: .showMenu)
                self.animateRideActionView(shouldShow: false)
            }
        }
    }
    func configureRideActionView(){
        print("I am configured")
        view.addSubview(rideActionView)
        rideActionView.delegate = self
        rideActionView.frame = CGRect(x: 0, y: view.frame.height, width: view.frame.width, height: rideActionViewHeight)
        
    }
    func animateRideActionView(shouldShow:Bool , destination : MKPlacemark? = nil, config:RideActionViewConfiguration? = nil , user:User? = nil){
        
        print("+++++++++++++++Called++++++++++++++++++")
//
        let yOrigin = shouldShow ? self.view.frame.height - self.rideActionViewHeight : self.view.frame.height
        UIView.animate(withDuration: 0.3) {
            self.rideActionView.frame.origin.y = yOrigin
        }
        if shouldShow {
            guard let config = config else { return }

            if  let destination = destination {
                rideActionView.destination = destination
            }
            if let user = user {
                rideActionView.user = user
            }
            rideActionView.config = config

        }
    }
    func observerCancelTrip(trip: Trip) {
        DriverService.shared.observeTripCancel(trip: trip) {
            self.removeAnnotationsAndOverlays()
            self.animateRideActionView(shouldShow: false)
            self.centerMapOnUserLocation()
        
            self.presentAlertController(withTitle: "Oops!", message: "The passenger has decided to cancel this ride. Press OK to continue.")
        }

    }
}

// Mark: - MKMapViewDelegate

extension HomeController : MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        guard let user = self.user else { return }
        guard user.accountType == 1 else { return }
        guard let location = userLocation.location else { return }
        DriverService.shared.updateDriverLocation(location: location)
    }
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let annotation = annotation as? DriverAnnotation {
            let view = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
            view.image = #imageLiteral(resourceName: "chevron-sign-to-right")
            return view
        }
        return nil
    }
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let route = self.route {
            let polyline = route.polyline
            let lineRender = MKPolylineRenderer(overlay: polyline)
            lineRender.strokeColor = .mainBlueTint
            lineRender.lineWidth = 3
            return lineRender
        }
        return MKOverlayRenderer()
    }
}

//Mark: - Map Helper functions

private extension  HomeController {
    func searchBy(naturalLanguageQuery: String , completion: @escaping([MKPlacemark])-> Void){
        
        var results = [MKPlacemark]()
        let request = MKLocalSearch.Request()
        request.region = mapView.region
        request.naturalLanguageQuery = naturalLanguageQuery
        let search = MKLocalSearch(request: request)
        search.start { (response, error) in
            guard let response = response else{return}
            response.mapItems.forEach({ (Item) in
                results.append(Item.placemark)
            })
            completion(results)
        }
    }
    func generatePolyline(toDestination destination : MKMapItem) {
        
        let request = MKDirections.Request()
        request.source = MKMapItem.forCurrentLocation()
        request.destination = destination
        request.transportType = .automobile
        
        let directionRequest = MKDirections(request: request)
        directionRequest.calculate { response, error in
            guard let response = response else { return }
            self.route = response.routes[0]
            guard let polyline = self.route?.polyline else { return }
            self.mapView.addOverlay(polyline)
            
        }
        
    }
    func removeAnnotationsAndOverlays() {
        mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? MKPointAnnotation {
                mapView.removeAnnotation(anno)
            }
        }
        
        if mapView.overlays.count > 0 {
            mapView.removeOverlay(mapView.overlays[0])
        }
    }
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager?.location?.coordinate else { return }
        let region = MKCoordinateRegion(center: coordinate, latitudinalMeters: 2000, longitudinalMeters: 2000)
        mapView.setRegion(region, animated: true)
    }
    
    func setCustomRegion(withType type: AnnotationType, coordinates: CLLocationCoordinate2D) {
        let region = CLCircularRegion(center: coordinates, radius: 25, identifier: type.rawValue)
        locationManager?.startMonitoring(for: region)
        
        print("DEBUG: Did set region \(region)")
    }
    
    func zoomForActiveTrip(withDriverUid uid: String) {
        var annotations = [MKAnnotation]()
        
        self.mapView.annotations.forEach { (annotation) in
            if let anno = annotation as? DriverAnnotation {
                if anno.uid == uid {
                    annotations.append(anno)
                }
            }
            
            if let userAnno = annotation as? MKUserLocation {
                annotations.append(userAnno)
            }
        }
        
        self.mapView.zoomToFit(annotations: annotations)
    }
}


// Mark: -  Location Services

extension HomeController : CLLocationManagerDelegate  {
    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        switch state {
        case .inside :
        print("+++++++++++++++++The Driver is inside the region+++++++++++++++++ ")
        case .outside:
            print("+++++++++++++++++The Driver is outside the region+++++++++++++++++ ")
        case .unknown:
            print("+++++++++++++++++The Driver is unknown the region+++++++++++++++++ ")
            
        }
    }
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        if region.identifier == AnnotationType.pickup.rawValue {
            print("+++++++++++++++++didStartMonitoringFor pickup+++++++++++++++++ ")
            print(region)
        }

        if region.identifier == AnnotationType.destination.rawValue {
            print("+++++++++++++++++didStartMonitoringFor destination+++++++++++++++++ ")
            print(region)
        }
       
        
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard let trip = self.trip else { return }
        print("+++++++++++++++++didEnterRegion+++++++++++++++++ ")
        if region.identifier == AnnotationType.pickup.rawValue {
            print("+++++++++++++++++didEnterRegion driverArrived +++++++++++++++++ ")
            DriverService.shared.updateTripState(trip: trip, state: .driverArrived) { (error, ref) in
                self.rideActionView.config = .pickupPassenger
            }
        }
        
        if region.identifier == AnnotationType.destination.rawValue {
            print("+++++++++++++++++didEnterRegion arrivedAtDestination +++++++++++++++++ ")
            DriverService.shared.updateTripState(trip: trip, state: .arrivedAtDestination) { (error, ref) in
                self.rideActionView.config = .endTrip
            }
        }
    }
    func enableLocationService(){
        locationManager?.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            locationManager?.requestWhenInUseAuthorization()
        case .restricted:
            break
        case .denied:
            break
        case .authorizedAlways:
            locationManager?.startUpdatingLocation()
            locationManager?.desiredAccuracy = kCLLocationAccuracyBest
        case .authorizedWhenInUse:
            locationManager?.requestAlwaysAuthorization()
        @unknown default:
            print("default")
        }
    }
  
}
extension HomeController : LocationInputViewActionDelegate {
    func presentLocationInputView() {
        inputActivationView.alpha = 0
        configureLocationViewInput()
    }
    
}

extension HomeController:LocationInputViewDelegate {
    func executeSearch(query: String) {
        searchBy(naturalLanguageQuery: query) { results in
            
            self.searchResults = results
            print(self.searchResults)
            self.tableView.reloadData()
        }
    }
    
    func dismissLocationInputActionView() {
        dismissLocationView { _ in
            UIView.animate(withDuration: 0.3) {
                self.inputActivationView.alpha = 1
            }
        }
        
}
    
    
}

//Mark : TableView

extension HomeController : UITableViewDelegate , UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return section == 0 ? "Saved Locations" : "Results"
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return section == 0 ? savedLocations.count : searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! LocationTableViewCell
        cell.separatorInset = UIEdgeInsets.init(top: 0.0, left: 8.0, bottom: 0.0, right: 8.0)
        cell.layoutMargins = UIEdgeInsets.init(top: 0.0, left: 100.0, bottom: 0.0, right: 0.0)
        var title1 = ""
        var title2 = ""
        var title3 = ""
        var title4 = ""
        var title5 = ""
        var title6 = ""
        if indexPath.section == 0 {
            if savedLocations.count > 0 {
            
                if "\(self.savedLocations[indexPath.row].thoroughfare)" == "" {
                    title4 = "Annamalai Coffee Bar"
                }
                else {
                    title4 = self.savedLocations[indexPath.row].thoroughfare ?? "Annamalai Coffee Bar"
                }
                if "\(self.savedLocations[indexPath.row].locality)" == "" {
                    title5 = "Arcot Road"
                }
                else {
                    title5 = self.savedLocations[indexPath.row].locality ?? "Arcot Road"
                }
                if "\(self.savedLocations[indexPath.row].administrativeArea)" == "" {
                    title6 = "Vellore"
                }
                else {
                    title6 = self.savedLocations[indexPath.row].administrativeArea ?? "Vellore"
                }
            }
            else {
                
            }
        }
        else  if indexPath.section == 1 {
            if searchResults.count > 0 {
            
                if "\(self.searchResults[indexPath.row].thoroughfare)" == "" {
                    title1 = "Annamalai Coffee Bar"
                }
                else {
                    title1 = self.searchResults[indexPath.row].thoroughfare ?? "Annamalai Coffee Bar"
                }
                if "\(self.searchResults[indexPath.row].locality)" == "" {
                    title2 = "Arcot Road"
                }
                else {
                    title2 = self.searchResults[indexPath.row].locality ?? "Arcot Road"
                }
                if "\(self.searchResults[indexPath.row].administrativeArea)" == "" {
                    title3 = "Vellore"
                }
                else {
                    title3 = self.searchResults[indexPath.row].administrativeArea ?? "Vellore"
                }
            }
            else {
                
            }
        }
        if indexPath.section == 0 {
            print(savedLocations)
            cell.placemark = savedLocations[indexPath.row]
            cell.titleLabel.text = savedLocations[indexPath.row].name
            cell.addressLabel.text = "\(title4),\(title5),\(title6)"
        }
        
        if indexPath.section == 1 {
            cell.placemark = searchResults[indexPath.row]
            cell.titleLabel.text = searchResults[indexPath.row].name
            cell.addressLabel.text = "\(title1),\(title2),\(title3)"
        }
   
        return UITableViewCell()
        
}
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let selectedPlacemark = indexPath.section == 0 ? savedLocations[indexPath.row] : searchResults[indexPath.row]
        
        configureActionButton(config: .dismissActionView)
        let destination = MKMapItem(placemark: selectedPlacemark)
        generatePolyline(toDestination: destination)
        dismissLocationView { _ in
            self.mapView.addAnnotationAndSelect(forCoordinate: selectedPlacemark.coordinate)
            let annotations = self.mapView.annotations.filter { !$0.isKind(of: DriverAnnotation.self) }
            self.mapView.zoomToFit(annotations: annotations)
            self.animateRideActionView(shouldShow: true, destination: selectedPlacemark, config: .requestRide)
        }
    }
    
}
extension HomeController : RideActionViewDelegate {

    func uploadTrip(_ view: RideActionView) {
          guard let pickupCoordinates = locationManager?.location?.coordinate else { return }
        guard let destinationCoordinates = view.destination?.coordinate else { return }
        
        shouldPresentLoadingView(true, message: "Finding your ride now....")
        
        PassengerService.shared.uploadTrip(pickupCoordinates, destinationCoordinates) {(err, ref) in
            if let error = err {
                print("failed to Uplaod Trip : \(error.localizedDescription)")
                return
            }
            UIView.animate(withDuration: 0.3, animations: {
                self.rideActionView.frame.origin.y = self.view.frame.height
            })
            self.observeCurrentTrip()
        }
    }
    func cancelTrip() {
        print("DEBUG Cancel Ride")
        PassengerService.shared.deleteTrip { error, ref in
            if let error = error {
                print("DEBUG : Error Deleting Trip")
                return
            }
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
            self.removeAnnotationsAndOverlays()
            
            self.actionButton.setImage(#imageLiteral(resourceName: "baseline_menu_black_36dp").withRenderingMode(.alwaysOriginal), for: .normal)
            self.actionButtonConfig = .showMenu
            
            self.inputActivationView.alpha = 1
        }
    }
    func pickupPassenger() {
        startTrip()
    }
    func dropOffPassenger() {
        guard let trip = self.trip else { return }
        DriverService.shared.updateTripState(trip: trip, state: .completed) { (error, ref) in
            self.removeAnnotationsAndOverlays()
            self.centerMapOnUserLocation()
            self.animateRideActionView(shouldShow: false)
        }
    }
    
    
    
    
}

//PickupControllerDelegate
extension HomeController : PickupControllerDelegate {
    func didAcceptTrip(_ trip: Trip) {
        self.trip = trip
        
        self.mapView.addAnnotationAndSelect(forCoordinate: trip.pickupCoordinates)
        
        setCustomRegion(withType: .pickup, coordinates: trip.pickupCoordinates)
        let placemark = MKPlacemark(coordinate: trip.pickupCoordinates)
        let mapItem = MKMapItem(placemark: placemark)
        generatePolyline(toDestination: mapItem)
        
        mapView.zoomToFit(annotations: mapView.annotations)
        
       // self.observerCancelTrip(trip: trip)
        self.observerCancelTrip(trip: trip)
                
        self.dismiss(animated: true) {
            Service.shared.fetchUserData(uid: trip.passengerUid) { passenger in
                self.animateRideActionView(shouldShow: true, config: .tripAccepted, user: passenger)
            }
        }
    }

    
}

//Mini
//13.069
//80.237617

//max
//13.069
//80.237617


//12.9338
//78.7193
//<+13.06069802,+80.25160789> 


//060698
//


//chennai
//13.067439
//80.237617


//Costa Coffee, 8, Harrington Road, Chetpet, Chennai, 600031, Tamil Nadu, India @ <+13.06945100,+80.23805400> +/- 0.00m, region CLCircularRegion (identifier:'<+13.06945100,+80.23805400> radius 141.17', center:<+13.06945100,+80.23805400>,
//pernambut
//12.878055°
//78.700788°
//Crisp Café, 1, Kothari Road, Nungambakkam, Egmore Nungambakkam, Tamil Nadu 600034, India @ <+13.06490500,+80.23914600> +/- 0.00m, region CLCircularRegion (identifier:'<+13.06490500,+80.23914600> radius 141.17', center:<+13.06490500,+80.23914600>, radius:141.17m)
//Zubair Ahmed Minni, Noor Ahmed 1st Street, Gudiyatham, Pernampattu, 635810, Tamil Nadu, India @ <+12.93855260,+78.71957780> +/- 0.00m, region CLCircularRegion (identifier:'<+12.93855260,+78.71957780> radius 141.17', center:<+12.93855260,+78.71957780>, radius:141.17m)
//Optional(<+12.93940735,+78.72566212> +/- 2000.00m (speed -1.00 mps / course -1.00) @ 22/10/21, 7:37:30 AM India Standard Time)
//I am configured

