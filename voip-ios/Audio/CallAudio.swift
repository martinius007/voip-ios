//
//  CallAudio.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation
import AudioToolbox

func configureAudioSession() {
    print("Configuring audio session")
    
    if AudioController.sharedInstance == nil {
        AudioController.sharedInstance = AudioController()
    }
}

func startAudio() {
    print("Starting audio")
    
    if AudioController.sharedInstance?.startIOUnit() == kAudioServicesNoError {
        AudioController.sharedInstance?.muteAudio = false
    } else {
        // handle error
    }
}

func stopAudio() {
    print("Stopping audio")
    if AudioController.sharedInstance?.stopIOUnit() != kAudioServicesNoError {
        // handle error
    }
}

