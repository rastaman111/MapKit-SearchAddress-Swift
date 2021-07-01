//
//  ViewController.swift
//  MapKit-Swift
//
//  Created by Александр Сибирцев on 01.07.2021.
//

import UIKit
import Contacts
import MapKit
import CoreLocation

class ViewController: UIViewController {

    let searchController = UISearchController(searchResultsController: nil)
    
    private let mapStreetLabel: UILabel = {
        let lbl = UILabel()
        lbl.textColor = .black
        lbl.font = .systemFont(ofSize: 17, weight: .semibold)
        lbl.textAlignment = .center
        lbl.numberOfLines = 0
        
        return lbl
    }()
    
    private let mapPin: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "mappin"))
        iv.tintColor = .black
        
        return iv
    }()
    
    private let mapView: MKMapView = {
        let mv = MKMapView()
        mv.showsTraffic = true
        mv.mapType = .standard
        mv.isZoomEnabled = true
        mv.isScrollEnabled = true
        mv.isUserInteractionEnabled = true
        mv.showsUserLocation = true
        mv.showsCompass = true
        mv.showsBuildings = true
        
        return mv
    }()
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
        
        checkLocationServices()

        searchController.searchBar.delegate = self
        navigationItem.searchController = searchController
        searchController.searchBar.setValue("Отмена", forKey: "cancelButtonText")
        searchController.searchBar.placeholder = "Поиск..."
        
        view.addSubview(mapView)
        mapView.delegate = self
        
        view.addSubview(mapPin)
        mapPin.anchor(top: nil, left: nil, bottom: nil, right: nil, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 25, height: 30)
        mapPin.centerXAnchor.constraint(equalTo: view.centerXAnchor, constant: 0).isActive = true
        mapPin.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        
        view.addSubview(mapStreetLabel)
        mapStreetLabel.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 15, paddingLeft: 20, paddingBottom: 0, paddingRight: 20, width: 0, height: 0)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        mapView.frame = view.bounds
    }

    func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            checkLocationAuthorization()
        } else {
            // Show alert letting the user know they have to turn this on.
        }
    }

    func checkLocationAuthorization() {
        switch CLLocationManager.authorizationStatus() {
        case .authorizedWhenInUse:
            mapView.showsUserLocation = true
        case .denied: // Show alert telling users how to turn on permissions
            break
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted: // Show an alert letting them know what’s up
            break
        case .authorizedAlways:
            mapView.showsUserLocation = true
        @unknown default:
            fatalError()
        }
    }
    
    func displayLocationInfo(placemark: CLPlacemark) {
        
        let address = placemark.postalAddress
        
        mapStreetLabel.text = "\(address?.city ?? ""), \(address?.street ?? "")"
        
        print("-----START UPDATE-----")
        print(placemark.subThoroughfare ?? "")
        print(placemark.thoroughfare ?? "")
        print(placemark.locality ?? "")
        print(placemark.postalCode ?? "")
        print(placemark.country ?? "")
        print("-----END OF UPDATE-----")
    }
}

//MARK: CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let currentLocation = locations.last!
        
        if currentLocation.horizontalAccuracy > 0 {
            //stop updating location to save battery life
            locationManager.stopUpdatingLocation()
           
            if let location = locations.last?.coordinate {
                let region = MKCoordinateRegion(center: location, latitudinalMeters: 5000, longitudinalMeters: 5000)
                mapView.setRegion(region, animated: true)
                
                CLGeocoder().reverseGeocodeLocation(manager.location!, completionHandler: { (placemarks, error) -> Void in
                    if error != nil {
                        print("Error: " + error!.localizedDescription)
                        return
                    }
               
                    if placemarks!.count > 0 {
                        let pm = placemarks![0]
                        self.displayLocationInfo(placemark: pm)
                    }
                })
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Errors: " + error.localizedDescription)
    }
}

//MARK: MKMapViewDelegate

extension ViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        let centre = mapView.centerCoordinate as CLLocationCoordinate2D
        let getLat: CLLocationDegrees = centre.latitude
        let getLon: CLLocationDegrees = centre.longitude
        
        let getMovedMapCenter: CLLocation =  CLLocation(latitude: getLat, longitude: getLon)
        
        CLGeocoder().reverseGeocodeLocation(getMovedMapCenter) { (placemarks, error) -> Void in
            if error != nil {
                print("Error: " + error!.localizedDescription)
                return
            }
            
            if placemarks!.count > 0 {
                let pm = placemarks![0]
                self.displayLocationInfo(placemark: pm)
            }
        }
    }
}

//MARK: UISearchBarDelegate

extension ViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchBarText = searchBar.text else { return }
        
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchBarText
        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        
        search.start { response, _ in
            guard let response = response else {
                return
            }
            
            guard let placemark = response.mapItems.first?.placemark else { return }
           
            let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
            let region = MKCoordinateRegion(center: placemark.coordinate, span: span)
            
            self.mapView.setRegion(region, animated: true)
            
            self.searchController.dismiss(animated: true, completion: nil)
        }
    }
}
