//
//  WsRequest.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation

class WsRequest : BaseType {
    
    var Id: String?
    var Name: NSNumber?
    var Params: BaseType?
    
    init(name: NSNumber) {
        self.Name = name
        // self.Name = NSNumber(value: name)
    }
    
    init(name: NSNumber, params: BaseType?) {
        // self.Name = NSNumber(value: name)
        self.Name = name
        self.Params = params
    }
    
    init(id: String, name: NSNumber, params: BaseType?) {
        self.Id = id
        self.Name = name
        self.Params = params
    }
    
    required init() {
        super.init()
    }
    
}
