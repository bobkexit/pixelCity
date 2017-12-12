//
//  MapVC.swift
//  pixel-city
//
//  Created by Николай Маторин on 11.12.2017.
//  Copyright © 2017 Николай Маторин. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapVC: UIViewController, UIGestureRecognizerDelegate {
    
    // Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var pullUpViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var pullUpView: UIView!
    
    //Variables
    var locationManager = CLLocationManager()
    var authStatus = CLLocationManager.authorizationStatus()
    
    //Constants
    let spinner = UIActivityIndicatorView()
    let progressLbl = UILabel()
    let screenSize = UIScreen.main.bounds
    let flowLayout = UICollectionViewFlowLayout()
    
    var collectionView: UICollectionView?
 
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        
        configureLocationServices()
        addDoubleTap()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: flowLayout)
        collectionView?.register(PhotoCell.self, forCellWithReuseIdentifier: PHOTO_CELL)
        collectionView?.delegate = self
        collectionView?.dataSource = self
        collectionView?.backgroundColor = #colorLiteral(red: 0.3411764801, green: 0.6235294342, blue: 0.1686274558, alpha: 1)
        pullUpView.addSubview(collectionView!)
    }

    @IBAction func centerMapBtnPressed(_ sender: Any) {
        if authStatus == .authorizedAlways || authStatus == .authorizedWhenInUse {
            centerMapOnUserLocation()
        }
    }
    
    func addDoubleTap() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(MapVC.dropPin(sender:)))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.delegate = self
        mapView.addGestureRecognizer(doubleTap)
        
        
    }
    
    func addSwipe() {
        let swipe = UISwipeGestureRecognizer(target: self, action: #selector(MapVC.animateViewDown))
        swipe.direction = .down
        pullUpView.addGestureRecognizer(swipe)
    }
    
    func animateViewUp() {
        pullUpViewHeightConstraint.constant = 300
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        if !(collectionView?.subviews.contains(spinner))! {
            configureSpinner()
            collectionView?.addSubview(spinner)
            spinner.startAnimating()
        }
        if !(collectionView?.subviews.contains(progressLbl))! {
            addProgressLbl()
            collectionView?.addSubview(progressLbl)
        }
    }
    
    @objc func animateViewDown() {
        FlickrDataService.instance.cancelAllSessions()
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func configureSpinner() {
        spinner.center = CGPoint(x: (pullUpView.frame.width / 2), y: (pullUpView.frame.height / 2))
        spinner.activityIndicatorViewStyle = .whiteLarge
        spinner.color = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        spinner.isHidden = false
        //spinner.startAnimating()
    }
    
    func addProgressLbl() {
        progressLbl.frame = CGRect(x: 0, y: (pullUpView.frame.height / 2) + 15, width: pullUpView.frame.width, height: 40)
        progressLbl.font = UIFont(name: "Avenir Next", size: 14)
        progressLbl.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        progressLbl.textAlignment = .center
        progressLbl.isHidden = false
    }
}

extension MapVC: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let pinAnnotation = MKPinAnnotationView(annotation: annotation, reuseIdentifier: DROPPABLE_PIN)
        pinAnnotation.pinTintColor = #colorLiteral(red: 0.9771530032, green: 0.7062081099, blue: 0.1748393774, alpha: 1)
        pinAnnotation.animatesDrop = true
        return pinAnnotation
    }
    
    func centerMapOnUserLocation() {
        guard let coordinate = locationManager.location?.coordinate else { return }
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, REGION_RADIUS * 2.0, REGION_RADIUS * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
    }
    
    @objc func dropPin(sender: UITapGestureRecognizer) {
        mapView.removeAnnotations(mapView.annotations)
        addSwipe()
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        animateViewUp()
       
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: DROPPABLE_PIN)
        mapView.addAnnotation(annotation)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, REGION_RADIUS * 2.0, REGION_RADIUS * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        FlickrDataService.instance.cancelAllSessions()
        FlickrDataService.instance.retrieveUrls(forAnnotation: annotation) { (success) in
            if success {
                FlickrDataService.instance.retrieveImges(progressLbl: self.progressLbl, completionHandler: { (success) in
                    if success {
                        self.spinner.isHidden = true
                        self.spinner.stopAnimating()
                        self.progressLbl.isHidden = true
                        //reload collectionView
                    }
                })
            }
        }
    }
}

extension MapVC: CLLocationManagerDelegate {
    func configureLocationServices() {
        if authStatus == .notDetermined {
            locationManager.requestAlwaysAuthorization()
        } else {
            return
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authStatus = status
        centerMapOnUserLocation()
    }
}

extension MapVC: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PHOTO_CELL, for: indexPath) as? PhotoCell
        return cell!
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
}
