//
//  WsCall.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation

class WsCall : BaseType {
    
    var channel_url: String?
    var data: String?
    var time: String?
    var login: String?
    var user_id: String?
    
    init(url: String) {
        self.channel_url = url
    }
    
    init(url: String, data: String) {
        self.channel_url = url
        self.data = data
    }
    
    required init() {
        super.init()
    }
    
}
