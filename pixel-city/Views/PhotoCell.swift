//
//  PhotoCell.swift
//  pixel-city
//
//  Created by Николай Маторин on 12.12.2017.
//  Copyright © 2017 Николай Маторин. All rights reserved.
//

import UIKit

class PhotoCell: UICollectionViewCell {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented ")
    }
    
    func configureCell(image: UIImage) {
        let imageView = UIImageView(image: image)
        self.addSubview(imageView)
    }
}
