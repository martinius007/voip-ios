//
//  AppSocketResponse.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation
import Starscream

public struct AppSocketResponse {
    
    var socket: WebSocket?
    var result: AnyObject
    
    var id: String?
    var msg: AnyObject?
    var type: AppSocketResponseType?
    var collection: String?
    var event: String?
    
    // MARK: Initializer
    
    init?(_ result: AnyObject, socket: WebSocket?) {
        self.result = result
        self.socket = socket
    }
    
    // MARK: Checks
        func isError() -> Bool {
        return false
    }
    
}

