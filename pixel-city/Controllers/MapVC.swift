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

class MapVC: UIViewController {
    
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
        collectionView?.backgroundColor = #colorLiteral(red: 0.9999960065, green: 1, blue: 1, alpha: 1)
        
        registerForPreviewing(with: self, sourceView: collectionView!)
        
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
            setupSpinner()
            collectionView?.addSubview(spinner)
        }
        if !(collectionView?.subviews.contains(progressLbl))! {
            setupProgressLabel()
            collectionView?.addSubview(progressLbl)
        }
        addSwipe()
    }
    
    @objc func animateViewDown() {
        FlickrDataService.instance.cancelAllSessions()
        pullUpViewHeightConstraint.constant = 0
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
    }
    
    func setupSpinner() {
        spinner.center = CGPoint(x: (pullUpView.frame.width / 2), y: (pullUpView.frame.height / 2))
        spinner.activityIndicatorViewStyle = .whiteLarge
        spinner.color = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
    }
    
    func setupProgressLabel() {
        progressLbl.frame = CGRect(x: 0, y: (pullUpView.frame.height / 2) + 15, width: pullUpView.frame.width, height: 40)
        progressLbl.font = UIFont(name: "Avenir Next", size: 14)
        progressLbl.textColor = #colorLiteral(red: 0.3333333433, green: 0.3333333433, blue: 0.3333333433, alpha: 1)
        progressLbl.textAlignment = .center
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
        
        let touchPoint = sender.location(in: mapView)
        let touchCoordinate = mapView.convert(touchPoint, toCoordinateFrom: mapView)

        animateViewUp()
       
        let annotation = DroppablePin(coordinate: touchCoordinate, identifier: DROPPABLE_PIN)
        mapView.addAnnotation(annotation)
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(touchCoordinate, REGION_RADIUS * 2.0, REGION_RADIUS * 2.0)
        mapView.setRegion(coordinateRegion, animated: true)
        
        progressLbl.isHidden = false
        spinner.isHidden = false
        spinner.startAnimating()
        
        FlickrDataService.instance.removeImages()
        self.collectionView?.reloadData()
        FlickrDataService.instance.cancelAllSessions()
        FlickrDataService.instance.retrieveUrls(forAnnotation: annotation) { (success) in
            if success {
                FlickrDataService.instance.retrieveImges(progressLbl: self.progressLbl, completionHandler: { (success) in
                    if success {
                        self.progressLbl.isHidden = true
                        self.spinner.isHidden = true
                        self.spinner.stopAnimating()
                        self.collectionView?.reloadData()
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
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PHOTO_CELL, for: indexPath) as? PhotoCell else { return UICollectionViewCell() }
        let imageFromIndex = FlickrDataService.instance.images[indexPath.row]
        cell.configureCell(image: imageFromIndex)
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return FlickrDataService.instance.images.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: POP_VC) as? PopVC else { return }
        popVC.initData(forImage: FlickrDataService.instance.images[indexPath.row])
        present(popVC, animated: true, completion: nil)
    }
}

extension MapVC: UIViewControllerPreviewingDelegate {
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = collectionView?.indexPathForItem(at: location), let cell = collectionView?.cellForItem(at: indexPath) else { return nil}
        
        guard let popVC = storyboard?.instantiateViewController(withIdentifier: POP_VC) as? PopVC else {
            return nil
        }
        
        popVC.initData(forImage: FlickrDataService.instance.images[indexPath.row])
        
        previewingContext.sourceRect = cell.contentView.frame
        
        return popVC
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        show(viewControllerToCommit, sender: self)
    }
    
}
