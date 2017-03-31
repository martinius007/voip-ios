//
//  SendCommand.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation
class SendCommand {
    
    var event: NSNumber
    var params: BaseType?
    var completion: MessageCompletion?
    
    init(event: NSNumber, params: BaseType?, completion: MessageCompletion?) {
        self.event = event
        self.params = params
        self.completion = completion
    }
}
