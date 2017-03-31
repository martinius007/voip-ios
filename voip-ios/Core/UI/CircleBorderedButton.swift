//
//  CircleBorderedButton.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation
import UIKit

class CircleBorderedButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        let radius: CGFloat = self.bounds.size.height / 2.0
        self.layer.cornerRadius = radius
        self.clipsToBounds = true
        
        self.backgroundColor = .clear
        self.layer.borderWidth = 1
        self.layer.borderColor = self.tintColor.cgColor
        
        self.contentEdgeInsets = UIEdgeInsets(top: 5, left: 10, bottom: 5, right: 10)
    }
}
