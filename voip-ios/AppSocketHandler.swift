//
//  AppSocketHandler.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation
import Starscream
import EVReflection

typealias Byte = UInt8

extension AppSocket {
    
    // Пришел пакет сообщений по сокету
    func handleMessage(json: String, socket: WebSocket) {
        let resList = [WsResponse](json: json)
        
        for res in resList {
            // Log.debug("socket handle message: \(res.event)")
            self.handleMessage(response: res, socket: socket)
        }
    }
    
    // Разбираем сообщение
    func handleMessage(response: WsResponse, socket: WebSocket) {
        guard let event = response.event else {
            return Log.debug("event is invalid: \(response)")
        }
        
        let data = response.data != nil ? response.data! : []
        
        switch event {
        case WsEvent.CMD_CONNECTED.rawValue: return handleConnect(response, socket: socket)
        case WsEvent.CMD_DISCONNECTED.rawValue: return handleDisconnect(response, socket: socket)
        case WsEvent.CMD_CONNECT_CHANNEL.rawValue: break
        case WsEvent.CMD_ERROR.rawValue: return handleError(data, socket: socket)
        case WsEvent.CMD_CALL_IN.rawValue: break
        case WsEvent.CMD_CALL_ACCEPT.rawValue: return handleCallIncomeAccept(data, socket: socket)
        case WsEvent.CMD_CALL_REJECT.rawValue: return handleCallIncomeReject(data, socket: socket)
        case WsEvent.CMD_CALL_HANGOUT.rawValue: return handleCallIncomeHangout(data, socket: socket)
        case WsEvent.CMD_CALL_VOICE_DATA.rawValue: return handleCallVoiceData(data, socket: socket)
        default: break
        }
    }

    // Произошло подключение к сокету
    private func handleConnect(_ result: WsResponse, socket: WebSocket) {
        internalConnectionHandler?(socket, true)
        internalConnectionHandler = nil
        
        for (_, handler) in connectionHandlers {
            handler.socketDidConnect(socket: self)
        }
        
        let handlers = events[WsEvent.CMD_CONNECTED]
        handlers?.forEach({ (handler) in
            handler([])
        })
        
        DispatchQueue.main.async {
            // NotificationCenter.default.post(name: "updateSpinner", object: nil, userInfo: ["percent":15])
            NotificationCenter.default.post(name: .AppSocketConnected, object: self)
        }
    }
    
    // Произошло отключение от сокета
    private func handleDisconnect(_ result: WsResponse, socket: WebSocket) {
        internalConnectionHandler?(socket, true)
        internalConnectionHandler = nil
        
        let handlers = events[WsEvent.CMD_DISCONNECTED]
        handlers?.forEach({ (handler) in
            handler([])
        })
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .AppSocketDisconnected, object: self)
        }
    }
    
    // Пришел звук (идет разговор)
    private func handleCallVoiceData(_ data: [NSDictionary], socket: WebSocket) {
        let callPackets = [WsCall](dictionaryArray: data)
        for cp in callPackets {
            DispatchQueue.global(qos: .background).async {
                if let data = Data(base64Encoded: cp.data!),
                    let ac = AudioController.sharedInstance {
                    ac.receiverAudio(audio: data)
                }
            }
        }
    }
    
    // Пользователь отклонил исходящий звонок
    private func handleCallIncomeReject(_ data: [NSDictionary], socket: WebSocket) {
        let callPackets = [WsCall](dictionaryArray: data)
        for cp in callPackets {
            if let ch = cp.channel_url, let handler = eventsOutgoingCall[ch] {
                handler(false)
                AppSocket.removeOutgoingSubscribe(ch)
            }
        }
    }
    
    // Пользователь принял исходящий звонок
    private func handleCallIncomeAccept(_ data: [NSDictionary], socket: WebSocket) {
        let callPackets = [WsCall](dictionaryArray: data)
        for cp in callPackets {
            if let ch = cp.channel_url, let handler = eventsOutgoingCall[ch] {
                handler(true)
                AppSocket.removeOutgoingSubscribe(ch)
            }
        }
    }
    
    // Пользователь завершил звонок
    private func handleCallIncomeHangout(_ data: [NSDictionary], socket: WebSocket) {
        if let call = self.callManager.getLastCall() {
            self.callManager.end(call: call)
        }
    }

    // Пришла ошибка
    private func handleError(_ data: [NSDictionary], socket: WebSocket) {
        let errors = [TypeError](dictionaryArray: data)
        
        for err in errors {
            if err.Code?.intValue == 401 { // invalid session
//                NotificationCenter.default.post(name: .LogoutNotification, object: self)
            }
        }
    }
}


