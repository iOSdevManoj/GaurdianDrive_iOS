//
//  MapViewVC.swift
//  GaurdianDrive
//
//  Created by KETAN on 26/12/25.
//

import CoreLocation
import GoogleMaps
import GooglePlaces
import UIKit

class MapViewVC: UIViewController {

    //Outlets...
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblChildName: UILabel!
    @IBOutlet weak var btnGetAddress: UIButton!
    @IBOutlet weak var viewForSearch: UIControl!
    @IBOutlet weak var cons_btnAddress_hight: NSLayoutConstraint!

//    //Variables..
    let geocoder = CLGeocoder()
    private var centerPin: UIImageView?
    private var liveMarker = GMSMarker()
    var childData = UserModel()
    var locationForChild = CLLocationCoordinate2D()
    var isFromAddress = false
    let locationManager = CLLocationManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        //Hide tabbar....
        self.tabBarController?.tabBar.isHidden = true
        if rootTab.cons_bottomBar_height != nil {
            rootTab.cons_bottomBar_height.constant = 0
            rootTab.viewBottomTabMain.isHidden = true
        }

        self.initialisation()
    }
}

extension MapViewVC {
    //MARK: - Initialisation..
    func initialisation() {
        self.mapView.delegate = self

        if !self.isFromAddress {
            mapView.isMyLocationEnabled = false
            mapView.settings.myLocationButton = false
            self.showLocationWithPin(
                lat: self.locationForChild.latitude, lng: self.locationForChild.longitude)
            self.lblChildName.text = childData.name
            self.viewForSearch.isHidden = true
            self.cons_btnAddress_hight.constant = 0
            // Intentionally DO NOT turn on location tracking for parent
        } else {
            mapView.isMyLocationEnabled = true
            mapView.settings.myLocationButton = true
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
            self.viewForSearch.isHidden = false
            self.lblChildName.isHidden = true
            self.cons_btnAddress_hight.constant = 45
            self.setupCenterPin()
        }
    }

    func showLocationWithPin(lat: Double, lng: Double, zoom: Float = 15) {

        let position = CLLocationCoordinate2D(latitude: lat, longitude: lng)

        // resize your custom pin image
        let img = UIImage(named: "ic_map_pin")?
            .aspectFitCanvas(size: CGSize(width: 32, height: 42))

        liveMarker.icon = img
        liveMarker.groundAnchor = CGPoint(x: 0.5, y: 1.0)
        liveMarker.position = position
        liveMarker.map = mapView

        // zoom camera
        let camera = GMSCameraPosition.camera(withTarget: position, zoom: zoom)
        mapView.animate(to: camera)

        self.getAddress(from: CLLocation(latitude: lat, longitude: lng))
    }

    func setupCenterPin() {

        let pin = UIImageView()
        pin.image = UIImage(named: "ic_map_pin")
        pin.translatesAutoresizingMaskIntoConstraints = false
        pin.contentMode = .scaleAspectFit

        view.addSubview(pin)

        NSLayoutConstraint.activate([
            pin.centerXAnchor.constraint(equalTo: mapView.centerXAnchor),
            pin.centerYAnchor.constraint(equalTo: mapView.centerYAnchor),
            pin.widthAnchor.constraint(equalToConstant: 32),
            pin.heightAnchor.constraint(equalToConstant: 42),
        ])

        centerPin = pin
    }
}

//MARK: - Setup Mapview all functions..
extension MapViewVC {
    //MARK: - Get Address
    private func getAddress(from location: CLLocation) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard let place = placemarks?.first else { return }

            let address = [
                place.name,
                place.locality,
                place.administrativeArea,
                place.country,
            ].compactMap { $0 }.joined(separator: ", ")

            print("📍 Address:", address)
            self.lblLocation.text = address
        }
    }
}

//MARK: - Click Events.....
extension MapViewVC {
    @IBAction func tapToBack(_ sender: UIControl) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func tapToSearch(_ sender: UIControl) {
        if self.isFromAddress {
            let autocomplete = GMSAutocompleteViewController()
            autocomplete.delegate = self
            present(autocomplete, animated: true)
        }
    }
    @IBAction func tapToGetAddress(_ sender: UIButton) {
        if self.isFromAddress {
            if let vcs = navigationController?.viewControllers {

                for vc in vcs {

                    if let addressVC = vc as? AddNewAddressVC {
                        addressVC.setupMapAddressFromLocation(
                            locationCordinate: self.locationForChild,
                            strAddress: self.lblLocation.text!)
                        navigationController?.popToViewController(addressVC, animated: true)
                        break
                    }
                }
            }
        }
    }
}
extension MapViewVC: CLLocationManagerDelegate {

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {

        guard let location = locations.last else { return }

        let coordinate = location.coordinate

        let camera = GMSCameraPosition.camera(
            withLatitude: coordinate.latitude,
            longitude: coordinate.longitude,
            zoom: 16
        )

        mapView.animate(to: camera)

        locationForChild = coordinate
        getAddress(from: location)

        locationManager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {

        switch manager.authorizationStatus {

        case .authorizedWhenInUse, .authorizedAlways:
            if self.isFromAddress {
                locationManager.startUpdatingLocation()
                mapView.isMyLocationEnabled = true
            }

        case .denied, .restricted:
            if self.isFromAddress {
                showDefaultLocation()
                self.showLocationPermissionAlert()
            }

        case .notDetermined:

            locationManager.requestWhenInUseAuthorization()

        @unknown default:
            break
        }
    }

    func showDefaultLocation() {

        let defaultLocation = CLLocationCoordinate2D(
            latitude: 39.8283,
            longitude: -98.5795
        )

        let camera = GMSCameraPosition.camera(
            withLatitude: defaultLocation.latitude,
            longitude: defaultLocation.longitude,
            zoom: 8
        )

        mapView.animate(to: camera)

        locationForChild = defaultLocation

        getAddress(
            from: CLLocation(
                latitude: defaultLocation.latitude,
                longitude: defaultLocation.longitude
            ))
    }

    func showLocationPermissionAlert() {

        let alert = UIAlertController(
            title: "Location Permission",
            message: "Please enable location to get current position.",
            preferredStyle: .alert
        )

        alert.addAction(
            UIAlertAction(title: "Settings", style: .default) { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            })

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        present(alert, animated: true)
    }
}

//MARK: - Places Api Delegates...
extension MapViewVC: GMSAutocompleteViewControllerDelegate {

    func viewController(
        _ viewController: GMSAutocompleteViewController,
        didAutocompleteWith place: GMSPlace
    ) {

        dismiss(animated: true)

        let coordinate = place.coordinate

        let camera = GMSCameraPosition.camera(
            withLatitude: coordinate.latitude,
            longitude: coordinate.longitude,
            zoom: 16
        )

        mapView.animate(to: camera)

        lblLocation.text = place.formattedAddress

        locationForChild = coordinate
    }

    func viewController(
        _ viewController: GMSAutocompleteViewController,
        didFailAutocompleteWithError error: Error
    ) {

        print(error.localizedDescription)
    }

    func wasCancelled(_ viewController: GMSAutocompleteViewController) {

        dismiss(animated: true)
    }
}

//MARK: - Mapview Delegates...
extension MapViewVC: GMSMapViewDelegate {
    func moveMapToLocation(lat: Double, lng: Double, zoom: Float = 16) {
        let camera = GMSCameraPosition.camera(
            withLatitude: lat,
            longitude: lng,
            zoom: zoom
        )
        mapView.animate(to: camera)
    }

    func mapView(_ mapView: GMSMapView, idleAt position: GMSCameraPosition) {

        if self.isFromAddress {

            let center = mapView.camera.target

            locationForChild = center

            getAddress(
                from: CLLocation(
                    latitude: center.latitude,
                    longitude: center.longitude
                ))
        }
    }
}

extension UIImage {
    func aspectFitCanvas(size: CGSize) -> UIImage {

        let widthRatio = size.width / self.size.width
        let heightRatio = size.height / self.size.height
        let ratio = min(widthRatio, heightRatio)

        let newSize = CGSize(
            width: self.size.width * ratio,
            height: self.size.height * ratio
        )

        let origin = CGPoint(
            x: (size.width - newSize.width) / 2,
            y: (size.height - newSize.height) / 2
        )

        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: CGRect(origin: origin, size: newSize))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return img ?? self
    }
}
