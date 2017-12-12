//
//  PopVC.swift
//  pixel-city
//
//  Created by Николай Маторин on 12.12.2017.
//  Copyright © 2017 Николай Маторин. All rights reserved.
//

import UIKit

class PopVC: UIViewController {
    
    // Outlets
    @IBOutlet weak var popImageView: UIImageView!
    
    // Variables
    var passedImage = UIImage()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        popImageView.image = passedImage
        
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(PopVC.pressedDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        view.addGestureRecognizer(doubleTap)
    }

    func initData(forImage image: UIImage) {
        self.passedImage = image
    }
    
    @objc func pressedDoubleTap() {
        dismiss(animated: true, completion: nil)
    }
}
