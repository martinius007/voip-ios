//
//  CallCell.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation

final class CallCell {
    
    // MARK: Metadata Properties
    
    let uuid: UUID
    let isOutgoing: Bool
    var handle: String?
    var channel: String?
    var isShown = false
    
    // MARK: Call State Properties
    
    var connectingDate: Date? {
        didSet {
            stateDidChange?()
            hasStartedConnectingDidChange?()
        }
    }
    
    var connectDate: Date? {
        didSet {
            stateDidChange?()
            hasConnectedDidChange?()
        }
    }
    
    var endDate: Date? {
        didSet {
            stateDidChange?()
            hasEndedDidChange?()
        }
    }
    
    var isOnHold = false {
        didSet {
            stateDidChange?()
        }
    }
    
    // MARK: State change callback blocks
    
    var stateDidChange: (() -> Void)?
    var hasStartedConnectingDidChange: (() -> Void)?
    var hasConnectedDidChange: (() -> Void)?
    var hasEndedDidChange: (() -> Void)?
    
    // MARK: Derived Properties
    
    var hasStartedConnecting: Bool {
        get {
            return connectingDate != nil
        }
        set {
            connectingDate = newValue ? Date() : nil
        }
    }
    
    var hasConnected: Bool {
        get {
            return connectDate != nil
        }
        set {
            connectDate = newValue ? Date() : nil
        }
    }
    
    var hasEnded: Bool {
        get {
            return endDate != nil
        }
        set {
            endDate = newValue ? Date() : nil
        }
    }
    
    var duration: TimeInterval {
        guard let connectDate = connectDate else {
            return 0
        }
        
        return Date().timeIntervalSince(connectDate)
    }
    
    // MARK: Initialization
    
    init(uuid: UUID, isOutgoing: Bool = false) {
        self.uuid = uuid
        self.isOutgoing = isOutgoing
    }
    
    init(uuid: UUID, channelUrl: String, isOutgoing: Bool = false) {
        self.uuid = uuid
        self.isOutgoing = isOutgoing
        self.channel = channelUrl
    }
    
    init(uuid: UUID, channel: String, isOutgoing: Bool = false) {
        self.uuid = uuid
        self.isOutgoing = isOutgoing
        self.channel = channel
    }
    
    // MARK: Actions
    
    func startSpeakerboxCall(completion: ((_ success: Bool) -> Void)?) {
        // Simulate the call starting successfully
        // completion?(true)
        
        Call.sharedInstance.send(channelUrl: self.channel!) { [weak weakSelf = self] (result: Bool) in
            // weakSelf?.hasConnected = true
            completion?(result)
        }
        
        /*
         Simulate the "started connecting" and "connected" states using artificial delays, since
         the example app is not backed by a real network service
         */
        
        /*
         DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 3) {
         self.hasStartedConnecting = true
         
         DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 1.5) {
         self.hasConnected = true
         }
         }
         */
    }
    
    func connectedSpeakerboxCall(completion: ((_ success: Bool) -> Void)?) {
        // Simulate the call starting successfully
        // completion?(true)
        
        completion?(true)
        self.hasConnected = true
        
        /*
         Simulate the "started connecting" and "connected" states using artificial delays, since
         the example app is not backed by a real network service
         */
        
        /*
         DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 3) {
         self.hasStartedConnecting = true
         
         DispatchQueue.main.asyncAfter(wallDeadline: DispatchWallTime.now() + 1.5) {
         self.hasConnected = true
         }
         }
         */
    }
    
    func answerSpeakerboxCall(completion: @escaping () -> Swift.Void) {
        /*
         Simulate the answer becoming connected immediately, since
         the example app is not backed by a real network service
         */
        
        Call.sharedInstance.answer(channelUrl: self.channel!) { [weak weakSelf = self] () in
            weakSelf?.hasConnected = true
            
            completion()
        }
    }
    
    func endSpeakerboxCall() {
        /*
         Simulate the end taking effect immediately, since
         the example app is not backed by a real network service
         */
        Call.sharedInstance.reject(channelUrl: self.channel!) { [weak weakSelf = self] () in
            weakSelf?.hasConnected = false
        }
        Call.sharedInstance.hangout(channelUrl: self.channel!) { [weak weakSelf = self] () in
            weakSelf?.hasConnected = false
        }
    }
    
}
