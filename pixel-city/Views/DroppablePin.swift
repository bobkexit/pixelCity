//
//  DroppablePin.swift
//  pixel-city
//
//  Created by Николай Маторин on 12.12.2017.
//  Copyright © 2017 Николай Маторин. All rights reserved.
//

import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    
    dynamic var coordinate: CLLocationCoordinate2D
    
    var identifier: String
    
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
    
}
