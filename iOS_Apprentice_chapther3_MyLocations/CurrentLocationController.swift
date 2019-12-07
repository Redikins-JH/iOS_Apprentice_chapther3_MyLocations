//
//  FirstViewController.swift
//  iOS_Apprentice_chapther3_MyLocations
//
//  Created by 정종학 on 2019/12/07.
//  Copyright © 2019 정종학. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationController: UIViewController, CLLocationManagerDelegate {
    
    let locationManager = CLLocationManager()
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeocoding = false
    var lastGeocodingError: Error?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        // Do any additional setup after loading the view.
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager,
            didFailWithError error: Error) {
      print("didFailWithError \(error.localizedDescription)")

      

       
      if (error as NSError).code ==
          CLError.locationUnknown.rawValue {
        return
      }
      lastLocationError = error
      stopLocationManager()
      updateLabels()
    }
    
    func stopLocationManager() {
      if updatingLocation {
        locationManager.stopUpdatingLocation()
        locationManager.delegate = nil
        updatingLocation = false
      }
    }
    

    func locationManager(_ manager: CLLocationManager,
      didUpdateLocations locations: [CLLocation]) {
      let newLocation = locations.last!
      print("didUpdateLocations \(newLocation)")
    
      // 1
      if newLocation.timestamp.timeIntervalSinceNow < -5 {
        return
      }

      // 2
      if newLocation.horizontalAccuracy < 0 {
        return
      }

      // 3
      if location == nil || location!.horizontalAccuracy >
                            newLocation.horizontalAccuracy {
        
        // 4
        lastLocationError = nil
        location = newLocation

        // 5
        if newLocation.horizontalAccuracy <=
           locationManager.desiredAccuracy {
          print("*** We're done!")
          stopLocationManager()
        }
        updateLabels()
   
        // The new code begins here:
        if !performingReverseGeocoding {
          print("*** Going to geocode")

          performingReverseGeocoding = true

          geocoder.reverseGeocodeLocation(newLocation,
                                          completionHandler: {
            placemarks, error in
                                            
            self.lastGeocodingError = error
            if error == nil, let p = placemarks, !p.isEmpty {
              self.placemark = p.last!
            } else {
              self.placemark = nil
            }

            self.performingReverseGeocoding = false
            self.updateLabels()
          })
                    
      }
    }
     // location = newLocation    // Add this
     // lastLocationError = nil
     // updateLabels()            // Add this
    }
    
    
    func configureGetButton() {
      if updatingLocation {
        getButton.setTitle("Stop", for: .normal)
      } else {
        getButton.setTitle("Get My Location", for: .normal)
      }
    }
    
    
    //updateLabels() 내부의 string 함수
    func string(from placemark: CLPlacemark) -> String {
      // 1
      var line1 = ""

      // 2
      if let s = placemark.subThoroughfare {
        line1 += s + " "
      }

      // 3
      if let s = placemark.thoroughfare {
        line1 += s
      }

      // 4
      var line2 = ""

      if let s = placemark.locality {
        line2 += s + " "
      }
      if let s = placemark.administrativeArea {
        line2 += s + " "
      }
      if let s = placemark.postalCode {
        line2 += s
      }
      
      // 5
      return line1 + "\n" + line2
    }
    
    func updateLabels() {
      if let location = location {
        latitudeLabel.text = String(format: "%.8f",
                                    location.coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f",
                                     location.coordinate.longitude)
        tagButton.isHidden = false
        messageLabel.text = ""
        // Add this block
        if let placemark = placemark {
          addressLabel.text = string(from: placemark)
        } else if performingReverseGeocoding {
          addressLabel.text = "Searching for Address..."
        } else if lastGeocodingError != nil {
          addressLabel.text = "Error Finding Address"
        } else {
          addressLabel.text = "No Address Found"
        }
        // End new code
      } else {
        latitudeLabel.text = ""
        longitudeLabel.text = ""
        addressLabel.text = ""
        tagButton.isHidden = true
        // The new code starts here:
        let statusMessage: String
        if let error = lastLocationError as NSError? {
          if error.domain == kCLErrorDomain &&
             error.code == CLError.denied.rawValue {
            statusMessage = "Location Services Disabled"
          } else {
            statusMessage = "Error Getting Location"
          }
        } else if !CLLocationManager.locationServicesEnabled() {
          statusMessage = "Location Services Disabled"
        } else if updatingLocation {
          statusMessage = "Searching..."
        } else {
          statusMessage = "Tap 'Get My Location' to Start"
        }
        messageLabel.text = statusMessage
      }
      configureGetButton()
    }
    
    func startLocationManager() {
      if CLLocationManager.locationServicesEnabled() {
        locationManager.delegate = self
        locationManager.desiredAccuracy =
                        kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        updatingLocation = true
      }
    }
  
    
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!

    // MARK:- Actions
    @IBAction func getLocation() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        let authStatus = CLLocationManager.authorizationStatus()
        
        
        if authStatus == .denied || authStatus == .restricted {
          showLocationServicesDeniedAlert()
          return
        }
        
        if authStatus == .notDetermined {
          locationManager.requestWhenInUseAuthorization()
          return
        }
        
        if updatingLocation {
          stopLocationManager()
        } else {
          location = nil
          lastLocationError = nil
          placemark = nil
          lastGeocodingError = nil
          startLocationManager()
        }
        
        updateLabels()
       
    }

    // MARK:- Helper Methods
    func showLocationServicesDeniedAlert() {
      let alert = UIAlertController(
        title: "Location Services Disabled",
        message: "Please enable location services for this app in Settings.",
        preferredStyle: .alert)

      let okAction = UIAlertAction(title: "OK", style: .default,
                                 handler: nil)
      alert.addAction(okAction)

      present(alert, animated: true, completion: nil)
    }
    
    
}

