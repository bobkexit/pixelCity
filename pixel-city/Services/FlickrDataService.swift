//
//  DataService.swift
//  pixel-city
//
//  Created by Николай Маторин on 12.12.2017.
//  Copyright © 2017 Николай Маторин. All rights reserved.
//

import Foundation
import Alamofire
import AlamofireImage

class FlickrDataService {
    static let instance = FlickrDataService()
    
    var imgUrls = [String]()
    var images = [UIImage]()
    
    func flickrUrl(withAnnotation annotation: DroppablePin) -> String {
        return "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(FLICKR_API_KEY)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=km&per_page=\(NUMBER_OF_PHOTOS)&format=json&nojsoncallback=1"
    }
    
    func retrieveUrls(forAnnotation annotation: DroppablePin, completionHandler: @escaping CompletionHandler) {
        Alamofire.request(flickrUrl(withAnnotation: annotation)).responseJSON { (response) in
            if response.result.error == nil {
                guard let json = response.result.value as? Dictionary<String, Any> else { return }
                let photosDict = json["photos"] as! Dictionary<String, Any>
                let photos = photosDict["photo"] as! [Dictionary<String, Any>]
                
                for photo in photos {
                    let postUrl = "https://farm\(photo["farm"]!).staticflickr.com/\(photo["server"]!)/\(photo["id"]!)_\(photo["secret"]!)_h_d.jpg"
                    self.imgUrls.append(postUrl)
                }
                
                completionHandler(true)
            } else {
                debugPrint(response.error as Any)
                completionHandler(false)
            }
        }
    }
    
    func retrieveImges(progressLbl: UILabel?, completionHandler: @escaping CompletionHandler) {        
        for url in imgUrls {
            Alamofire.request(url).responseImage(completionHandler: { (response) in
                if response.result.error == nil {
                    guard let image = response.result.value else { return }
                    self.images.append(image)
                    progressLbl?.text = "\(self.images.count)/\(NUMBER_OF_PHOTOS) images downloaded"
                    
                    if self.images.count == self.imgUrls.count {
                        completionHandler(true)
                    }
                } else {
                    debugPrint(response.error as Any)
                    completionHandler(false)
                }
            })
        }
    }
    
    func cancelAllSessions() {
        Alamofire.SessionManager.default.session.getTasksWithCompletionHandler { (sessionDataTask, uploadData, downloadData) in
            sessionDataTask.forEach({ $0.cancel() })
            downloadData.forEach({ $0.cancel() })
        }
    }
    
    func removeImages() {
        self.imgUrls.removeAll()
        self.images.removeAll()
    }
}
