//
//  PickupController.swift
//  UberClone
//
//  
//

import UIKit
import MapKit
import AVFoundation

protocol PickupControllerDelegate : AnyObject {
    func didAcceptTrip(_ trip :Trip)
}

class PickupController : UIViewController, MKMapViewDelegate {
    
    // Mark: - Properties
    weak var delegate : PickupControllerDelegate?
    private let mapView = MKMapView()
    var SoundEffect: AVAudioPlayer?
    let trip :Trip

    private let cancelButton : UIButton = {
        let button = UIButton(type: .system)
        button.setImage(#imageLiteral(resourceName: "baseline_clear_white_36pt_2x").withRenderingMode(.alwaysOriginal), for: .normal)
        button.addTarget(self, action: #selector(handleDismiss), for: .touchUpInside)
        return button
        
    }()
    private let pickupLabel : UILabel = {
        let label = UILabel()
        label.text = "Would you like to Pickup this Passenger?"
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white
        return label
    }()
    private let acceptTripButton : UIButton = {
        let button = UIButton(type: .system)
        button.addTarget(self, action: #selector(handleAcceptTrip), for: .touchUpInside)
        button.backgroundColor = .white
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.setTitle("ACCEPT TRIP", for: .normal)
        button.setTitleColor(.black, for: .normal)
        return button
        
    }()
    private lazy var circularProgressView: CircularProgressView = {
        let frame = CGRect(x: 0, y: 0, width: 360, height: 360)
        let cp = CircularProgressView(frame: frame)
        
        cp.addSubview(mapView)
        mapView.setDimension(height: 268, width: 268)
        mapView.layer.cornerRadius = 268 / 2
        mapView.centerX(inView: cp)
        mapView.centerY(inView: cp, constant: 32)
        return cp
    }()
    
    

    // Mark: - Life Cycle
    init(trip:Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()

        let path = Bundle.main.path(forResource: "Uber Ringtone.mp3", ofType:nil)!
        let url = URL(fileURLWithPath: path)

        do {
            SoundEffect = try AVAudioPlayer(contentsOf: url)
            SoundEffect?.play()
        } catch {
            // couldn't load file :(
        }
        configureUI()
        configureMapView()
        self.perform(#selector(animateProgress), with: nil, afterDelay: 0.5)
        
    }
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    
    
    // Mark: - Helper Functions
    func configureUI() {
        view.backgroundColor = .backgroundColor
        
        view.addSubview(cancelButton)
        cancelButton.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor,
                            paddingLeft: 16)
        
        view.addSubview(circularProgressView)
        circularProgressView.setDimension(height: 360, width: 360)
        circularProgressView.anchor(top: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        circularProgressView.centerX(inView: view)
        
        view.addSubview(pickupLabel)
        pickupLabel.centerX(inView: view)
        pickupLabel.anchor(top: circularProgressView.bottomAnchor, paddingTop: 32)
        
        view.addSubview(acceptTripButton)
        acceptTripButton.anchor(top: pickupLabel.bottomAnchor, left: view.leftAnchor,
                                right: view.rightAnchor, paddingTop: 16, paddingLeft: 32,
                                paddingRight: 32, height: 50)
        
    }
    func configureMapView(){
        let region = MKCoordinateRegion(center: trip.pickupCoordinates, latitudinalMeters: 1000, longitudinalMeters: 1000)
        mapView.setRegion(region, animated: true)
        let anno = MKPointAnnotation()
        anno.coordinate = trip.pickupCoordinates
        mapView.addAnnotation(anno)
        self.mapView.selectAnnotation(anno, animated: true)
        
    }
    @objc func animateProgress() {
        circularProgressView.animatePulsatingLayer()
        circularProgressView.setProgressWithAnimation(duration: 10, value: 0) {
//            DispatchQueue.main.async {
//                DriverService.shared.updateTripState(trip: self.trip, state: .denied) { (err, ref) in
//                    self.dismiss(animated: true, completion: nil)
//                }
//            }
//
        }
    }
    
    
    
    
    // Mark: - Selectors
    @objc func handleDismiss(){
        self.dismiss(animated: true, completion: nil)
    }
    @objc func handleAcceptTrip(){
        DriverService.shared.acceptTrip(trip: trip) { error, ref in
            self.SoundEffect?.stop()
            self.delegate?.didAcceptTrip(self.trip)
        }
    }
    
    // Mark: - API
    

    
    
    
    
    
}
 
