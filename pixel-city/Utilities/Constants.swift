//
//  Constants.swift
//  pixel-city
//
//  Created by Николай Маторин on 12.12.2017.
//  Copyright © 2017 Николай Маторин. All rights reserved.
//

import Foundation

// API Kyes
let FLICKR_API_KEY = "4db2cc7a196f1a82af5324406c5d1ea8"

// Reusable ids
let DROPPABLE_PIN = "droppablePin"
let PHOTO_CELL = "photoCell"

//
let REGION_RADIUS: Double = 1000
let NUMBER_OF_PHOTOS = 40

// URL
func flickrUrl(withAnnotation annotation: DroppablePin) -> String {
    return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(FLICKR_API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=km&per_page=\(NUMBER_OF_PHOTOS)&format=json&nojsoncallback=1"
}

