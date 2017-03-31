//
//  AppSocketCall.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation

extension AppSocket {
    
    static func callSend(channelUrl: String, completion: @escaping OutgoingCall) {
        subscribeOutgoingCall(channelUrl, completion: completion)
        let call = WsCall(url: channelUrl)
        send(event: WsEvent.CMD_CALL_IN.rawValue, params: call)
    }
    
    static func callAnswer(channelUrl: String, completion: @escaping () -> Swift.Void) {
        let call = WsCall(url: channelUrl)
        send(event: WsEvent.CMD_CALL_ACCEPT.rawValue, params: call)
        
        completion()
    }
    
    static func callReject(channelUrl: String, completion: @escaping () -> Swift.Void) {
        let call = WsCall(url: channelUrl)
        send(event: WsEvent.CMD_CALL_REJECT.rawValue, params: call)
        
        completion()
    }
    
    static func callHangout(channelUrl: String, completion: @escaping () -> Swift.Void) {
        let call = WsCall(url: channelUrl)
        send(event: WsEvent.CMD_CALL_HANGOUT.rawValue, params: call)
        
        completion()
    }
    
    static func callVoiceData(channelUrl: String, data: String) {
        let call = WsCall(url: channelUrl, data: data)
        send(event: WsEvent.CMD_CALL_VOICE_DATA.rawValue, params: call)
    }
    
}
