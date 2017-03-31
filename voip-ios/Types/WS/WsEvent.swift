//
//  WsEvent.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation

enum WsEvent: NSNumber {
    
    // inner events
    
    case CMD_CONNECTED          = -1
    case CMD_DISCONNECTED       = -2
    
    // public events
    
    case CMD_CONNECT_CHANNEL    = 5
    case CMD_ERROR              = 7
    case CMD_CALL_IN            = 12
    case CMD_CALL_ACCEPT        = 13
    case CMD_CALL_REJECT        = 14
    case CMD_CALL_HANGOUT       = 15
    case CMD_CALL_VOICE_DATA    = 16
    
}
