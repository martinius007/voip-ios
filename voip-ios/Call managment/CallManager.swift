//
//  CallManager.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation
import CallKit

final class CallManager: NSObject {
    
    let callController = CXCallController()
    
    // MARK: Actions
    
    func startCall(handle: String, video: Bool = false) {
        let handle = CXHandle(type: .phoneNumber, value: handle)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        
        startCallAction.isVideo = video
        
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        
        requestTransaction(transaction)
    }
    
    func startCall(channel: String, video: Bool = false) {
        let handle = CXHandle(type: .generic, value: channel)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        
        //        Call.sharedInstance.send(channelUrl: channel.url!) { _ in
        
        //        }
        
        startCallAction.isVideo = video
        
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        
        requestTransaction(transaction)
    }
    
    func outgoingStart(channel: String, video: Bool = false) {
        let handle = CXHandle(type: .generic, value: channel)
        let startCallAction = CXStartCallAction(call: UUID(), handle: handle)
        
        Call.sharedInstance.send(channelUrl: channel) {_ in
            //
        }
        
        startCallAction.isVideo = video
        
        let transaction = CXTransaction()
        transaction.addAction(startCallAction)
        
        requestTransaction(transaction)
    }
    
    func end(call: CallCell) {
        let endCallAction = CXEndCallAction(call: call.uuid)
        let transaction = CXTransaction()
        transaction.addAction(endCallAction)
        
        requestTransaction(transaction)
    }
    
    func setHeld(call: CallCell, onHold: Bool) {
        let setHeldCallAction = CXSetHeldCallAction(call: call.uuid, onHold: onHold)
        let transaction = CXTransaction()
        transaction.addAction(setHeldCallAction)
        
        requestTransaction(transaction)
    }
    
    private func requestTransaction(_ transaction: CXTransaction) {
        callController.request(transaction) { error in
            if let error = error {
                Log.debug("Error requesting transaction: \(error)")
            } else {
                Log.debug("Requested transaction successfully")
            }
        }
    }
    
    // MARK: Call Management
    
    static let CallsChangedNotification = Notification.Name("CallManagerCallsChangedNotification")
    static let CallsAcceptNotification  = Notification.Name("CallManagerCallsAcceptNotification")
    static let CallsRejectNotification  = Notification.Name("CallManagerCallsRejectNotification")
    static let CallsHangoutNotification = Notification.Name("CallManagerCallsHangoutNotification")
    static let CallsIncomeNotification  = Notification.Name("CallManagerCallsIncomeNotification")
    
    private(set) var calls = [CallCell]()
    
    func callWithUUID(uuid: UUID) -> CallCell? {
        guard let index = calls.index(where: { $0.uuid == uuid }) else {
            return nil
        }
        return calls[index]
    }
    
    func addCall(_ call: CallCell) {
        calls.append(call)
        
        call.stateDidChange = { [weak self] in
            self?.postCallsChangedNotification()
        }
        
        postCallsChangedNotification()
    }
    
    func failCall(_ call: CallCell) {
        // calls.append(call)
        
        call.stateDidChange = { [weak self] in
            self?.postCallsChangedNotification()
        }
        
        postCallsChangedNotification()
    }
    
    func removeCall(_ call: CallCell) {
        calls.removeFirst()
        // calls.removeFirst(where: { $0 === call })
        postCallsChangedNotification()
        // postCallsHangoutNotification()
    }
    
    func getLastCall() -> CallCell? {
        return calls.last
    }
    
    func removeAllCalls() {
        calls.removeAll()
        postCallsChangedNotification()
        // postCallsHangoutNotification()
    }
    
    private func postCallsChangedNotification() {
        NotificationCenter.default.post(name: type(of: self).CallsChangedNotification, object: self)
    }
    
    private func postCallsAcceptNotification() {
        NotificationCenter.default.post(name: type(of: self).CallsAcceptNotification, object: self)
    }
    
    private func postCallsRejectNotification() {
        NotificationCenter.default.post(name: type(of: self).CallsRejectNotification, object: self)
    }
    
    private func postCallsHangoutNotification() {
        NotificationCenter.default.post(name: type(of: self).CallsHangoutNotification, object: self)
    }
    
    private func postCallsIncomeNotification() {
        NotificationCenter.default.post(name: type(of: self).CallsIncomeNotification, object: self)
    }
    
    // MARK: SpeakerboxCallDelegate
    
    func speakerboxCallDidChangeState(_ call: CallCell) {
        postCallsChangedNotification()
    }
}

