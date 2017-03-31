//
//  TypeError.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation

class TypeError: BaseType {
    
    var Code: NSNumber?
    var Text: String?
    
    // json convert
    override public func propertyMapping() -> [(String?, String?)] {
        return [("code", "Code"), ("text", "Text")]
    }
    
    required init() {
        super.init()
    }
    
}
