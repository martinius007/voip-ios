//
//  WsResponse.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation

/**
 Универсальный ответ по сокету, в зависимости от того какой event вернется изменяется класс data
 */
class WsResponse : BaseType {
    
    var id: String?
    var event: NSNumber?
    var data: [NSDictionary]?
    
    init(event: NSNumber) {
        self.event = event
    }
    
    required init() {
        super.init()
    }
    
}
