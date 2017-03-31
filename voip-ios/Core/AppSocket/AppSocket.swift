//
//  AppSocket.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation
import Starscream
import EVReflection

// public typealias RequestCompletion = (JSON?, Bool) -> Void
public typealias MessageCompletion = (AppSocketResponse) -> Void
public typealias EventCompletion = ([AnyObject]) -> Void
public typealias AppSocketCompletion = (WebSocket?, Bool) -> Void
public typealias MessageCompletionObject <T: AnyObject> = (T) -> Void
public typealias MessageCompletionObjectsList <T: AnyObject> = ([T]) -> Void

public typealias OutgoingCall = (Bool) -> Void

protocol AppSocketConnectionHandler {
    func socketDidConnect(socket: AppSocket)
    func socketDidDisconnect(socket: AppSocket)
}

let appSocketQueue = DispatchQueue(label: "voip-call.websocket", attributes: .concurrent)

class AppSocket {
    
    static let sharedInstance = AppSocket()
    
    let callManager = AppDelegate.shared.callManager
    
    var serverURL: URL?
    
    var socket: WebSocket?
    var queue: [String: MessageCompletion] = [:]
    var events: [WsEvent: [EventCompletion]] = [:]
    
    static var sendStorage: [SendCommand] = []
    
    internal var internalConnectionHandler: AppSocketCompletion?
    internal var connectionHandlers: [String: AppSocketConnectionHandler] = [:]
    
    // MARK: Connection
    
    public static func establishConnection(_ url: URL, completion: @escaping AppSocketCompletion) {
        sharedInstance.serverURL = url
        sharedInstance.internalConnectionHandler = completion
        
        sharedInstance.socket = WebSocket(url: url)
        sharedInstance.socket?.callbackQueue = appSocketQueue
        
        sharedInstance.socket?.delegate = sharedInstance
        sharedInstance.socket?.pongDelegate = sharedInstance
        
        sharedInstance.socket?.connect()
    }
    
    public static func closeConnection(_ completion: @escaping AppSocketCompletion) {
        sharedInstance.internalConnectionHandler = completion
        sharedInstance.socket?.disconnect()
    }
    
    public static func closeConnection() {
        sharedInstance.socket?.disconnect()
    }
    
    // MARK: Messages
    
    static func send(event: NSNumber, params: BaseType?, completion: MessageCompletion? = nil) {
        let request = WsRequest(id: String.random(50), name: event, params: params)
        
        let raw = request.toJsonString()
        // Log.debug("Socket will send message: \(raw)")
        
        if let socket = sharedInstance.socket, socket.isConnected {
            sharedInstance.socket?.write(string: raw)
            
            if completion != nil {
                sharedInstance.queue[request.Id!] = completion
            }
        } else {
            sendStorage.append(SendCommand(event: event, params: params, completion: completion))
        }
    }
    
    
    static func subscribe(event: WsEvent, completion: @escaping EventCompletion) {
        if var list = sharedInstance.events[event] {
            list.append(completion)
            sharedInstance.events[event] = list
        } else {
            sharedInstance.events[event] = [completion]
        }
    }
    
    
    // Outgoing call handlers
    var eventsOutgoingCall: [String: OutgoingCall] = [:]
    
    static func subscribeOutgoingCall(_ url: String, completion: @escaping OutgoingCall) {
        sharedInstance.eventsOutgoingCall[url] = completion
    }
    
    static func removeOutgoingSubscribe(_ url: String) {
        sharedInstance.eventsOutgoingCall[url] = nil
    }
    
}

// MARK: Helpers

extension AppSocket {
    
    static func reconnect() {
    }
    
    static func isConnected() -> Bool {
        return self.sharedInstance.socket?.isConnected ?? false
    }
    
}

// MARK: Connection handlers

extension AppSocket {
    
    static func addConnectionHandler(token: String, handler: AppSocketConnectionHandler) {
        sharedInstance.connectionHandlers[token] = handler
    }
    
    static func removeConnectionHandler(token: String) {
        sharedInstance.connectionHandlers[token] = nil
    }
    
}

// MARK: WebSocketDelegate

extension AppSocket: WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocket) {
        Log.debug("WebSocket (\(socket)) did connect")
        
        for cmd in AppSocket.sendStorage {
            AppSocket.send(event: cmd.event, params: cmd.params, completion: cmd.completion)
        }
        AppSocket.sendStorage = []
        
        let res = WsResponse(event: WsEvent.CMD_CONNECTED.rawValue)
        self.handleMessage(response: res, socket: socket)
    }
    
    func websocketDidDisconnect(socket: WebSocket, error: NSError?) {
        Log.debug("[WebSocket] did disconnect with error (\(error))")
        
        internalConnectionHandler?(socket, socket.isConnected)
        internalConnectionHandler = nil
        
        let res = WsResponse(event: WsEvent.CMD_DISCONNECTED.rawValue)
        self.handleMessage(response: res, socket: socket)
        
        socket.connect() // will reconnect on disconnect
    }
    
    func websocketDidReceiveData(socket: WebSocket, data: Data) {
        Log.debug("[WebSocket] did receive data (\(data))")
    }
    
    func websocketDidReceiveMessage(socket: WebSocket, text: String) {
        self.handleMessage(json: text, socket: socket)
    }
    
}

// MARK: WebSocketPongDelegate

extension AppSocket: WebSocketPongDelegate {
    
    func websocketDidReceivePong(socket: WebSocket, data: Data?) {
        Log.debug("[WebSocket] did receive pong")
    }
    
}
