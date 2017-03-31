//
//  AudioController.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//
import AudioToolbox
import AVFoundation

@objc(AudioController)
class AudioController: NSObject {
    
    static let sampleRate = 8000.0
    
    var _channelUrl: String?
    var _rioUnit: AudioUnit? = nil
    
    static var sharedInstance: AudioController?
    var receivedPCMBuffer: TPCircularBuffer = TPCircularBuffer()

    var g729EncoderDecoder: G729Wrapper!
    
    var muteAudio: Bool
    private(set) var audioChainIsBeingReconstructed: Bool = false
    
    override init() {
        TPCircularBufferClear(&receivedPCMBuffer)
        TPCircularBufferInit(&receivedPCMBuffer, 10000000)
        g729EncoderDecoder = G729Wrapper()
        g729EncoderDecoder!.open()
        muteAudio = true
        super.init()

        self.setupAudioChain()
    }
    
    func receiverAudio(audio: Data) {
        var isBufferProduceBytes: CBool = false
        
        var array = [UInt8](audio)
        var receivedShort: [CShort] = [CShort](repeating: 0, count: 1024)

        let numberOfDecodedShorts: CInt = g729EncoderDecoder.decode(withG729: &array, andSize: Int32(array.count), andEncodedPCM: &receivedShort)
        isBufferProduceBytes = TPCircularBufferProduceBytes(&receivedPCMBuffer, receivedShort, (numberOfDecodedShorts * 2))
        if !isBufferProduceBytes {
        }
    }
    
    func handleInterruption(_ notification: Notification) {
        // do {
        let theInterruptionType = (notification as NSNotification).userInfo![AVAudioSessionInterruptionTypeKey] as! UInt
        NSLog("Session interrupted > --- %@ ---\n", theInterruptionType == AVAudioSessionInterruptionType.began.rawValue ? "Begin Interruption" : "End Interruption")
        
        if theInterruptionType == AVAudioSessionInterruptionType.began.rawValue {
            self.stopIOUnit()
        }
        
        if theInterruptionType == AVAudioSessionInterruptionType.ended.rawValue {
            // make sure to activate the session
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch let error as NSError {
                NSLog("AVAudioSession set active failed with error: %@", error)
            } catch {
                fatalError()
            }
            
            self.startIOUnit()
        }
    }
    
    func handleRouteChange(_ notification: Notification) {
        let reasonValue = (notification as NSNotification).userInfo![AVAudioSessionRouteChangeReasonKey] as! UInt
        let routeDescription = (notification as NSNotification).userInfo![AVAudioSessionRouteChangePreviousRouteKey] as! AVAudioSessionRouteDescription?
        
        NSLog("Route change:")
        if let reason = AVAudioSessionRouteChangeReason(rawValue: reasonValue) {
            switch reason {
            case .newDeviceAvailable:
                NSLog("     NewDeviceAvailable")
            case .oldDeviceUnavailable:
                NSLog("     OldDeviceUnavailable")
            case .categoryChange:
                NSLog("     CategoryChange")
                NSLog(" New Category: %@", AVAudioSession.sharedInstance().category)
            case .override:
                NSLog("     Override")
            case .wakeFromSleep:
                NSLog("     WakeFromSleep")
            case .noSuitableRouteForCategory:
                NSLog("     NoSuitableRouteForCategory")
            case .routeConfigurationChange:
                NSLog("     RouteConfigurationChange")
            case .unknown:
                NSLog("     Unknown")
            }
        } else {
            NSLog("     ReasonUnknown(%zu)", reasonValue)
        }
        
        if let prevRout = routeDescription {
            NSLog("Previous route:\n")
            NSLog("%@", prevRout)
            NSLog("Current route:\n")
            NSLog("%@\n", AVAudioSession.sharedInstance().currentRoute)
        }
    }
    
    func handleMediaServerReset(_ notification: Notification) {
        NSLog("Media server has reset")
        audioChainIsBeingReconstructed = true
        
        usleep(25000) //wait here for some time to ensure that we don't delete these objects while they are being accessed elsewhere
        self.setupAudioChain()
        self.startIOUnit()
        
        audioChainIsBeingReconstructed = false
    }
    
    private func setupAudioSession() {
        do {
            // Configure the audio session
            let sessionInstance = AVAudioSession.sharedInstance()
            
            // we are going to play and record so we pick that category
            do {
                try sessionInstance.setCategory(AVAudioSessionCategoryPlayAndRecord)
            } catch let error as NSError {
                try XExceptionIfError(error, "couldn't set session's audio category")
            } catch {
                fatalError()
            }
            
            // set the buffer duration to 5 ms
            let bufferDuration: TimeInterval = 0.02
            do {
                try sessionInstance.setPreferredIOBufferDuration(bufferDuration)
            } catch let error as NSError {
                try XExceptionIfError(error, "couldn't set session's I/O buffer duration")
            } catch {
                fatalError()
            }
            
            do {
                // set the session's sample rate
                try sessionInstance.setPreferredSampleRate(AudioController.sampleRate)
            } catch let error as NSError {
                try XExceptionIfError(error, "couldn't set session's preferred sample rate")
            } catch {
                fatalError()
            }
            
            // add interruption handler
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(AudioController.handleInterruption(_:)),
                                                   name: NSNotification.Name.AVAudioSessionInterruption,
                                                   object: sessionInstance)
            
            // we don't do anything special in the route change notification
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(AudioController.handleRouteChange(_:)),
                                                   name: NSNotification.Name.AVAudioSessionRouteChange,
                                                   object: sessionInstance)
            
            // if media services are reset, we need to rebuild our audio chain
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(AudioController.handleMediaServerReset(_:)),
                                                   name: NSNotification.Name.AVAudioSessionMediaServicesWereReset,
                                                   object: sessionInstance)
            
            do {
                // activate the audio session
                try sessionInstance.setActive(true)
            } catch let error as NSError {
                try XExceptionIfError(error, "couldn't set session active")
            } catch {
                fatalError()
            }
        } catch let e as CAXException {
            NSLog("Error returned from setupAudioSession: %d: %@", Int32(e.mError), e.mOperation)
        } catch _ {
            NSLog("Unknown error returned from setupAudioSession")
        }
        
    }
    
    
    private func setupIOUnit() {
        do {
            // Create a new instance of AURemoteIO
            
            var desc = AudioComponentDescription(
                componentType: OSType(kAudioUnitType_Output),
                // componentSubType: OSType(kAudioUnitSubType_RemoteIO),
                componentSubType: OSType(kAudioUnitSubType_VoiceProcessingIO),
                componentManufacturer: OSType(kAudioUnitManufacturer_Apple),
                componentFlags: 0,
                componentFlagsMask: 0)
            
            let comp = AudioComponentFindNext(nil, &desc)
            try XExceptionIfError(AudioComponentInstanceNew(comp!, &self._rioUnit), "couldn't create a new instance of AURemoteIO")
            
            //  Enable input and output on AURemoteIO
            //  Input is enabled on the input scope of the input element
            //  Output is enabled on the output scope of the output element
            
            var one: UInt32 = 1
            try XExceptionIfError(AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Input), 1, &one, SizeOf32(one)), "could not enable input on AURemoteIO")
            try XExceptionIfError(AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioOutputUnitProperty_EnableIO), AudioUnitScope(kAudioUnitScope_Output), 0, &one, SizeOf32(one)), "could not enable output on AURemoteIO")
            
            var ioFormat = AudioStreamBasicDescription()

            ioFormat.mSampleRate = 8000.00
            ioFormat.mFormatID = kAudioFormatLinearPCM
            ioFormat.mFormatFlags = kAudioFormatFlagIsSignedInteger | kAudioFormatFlagIsPacked
            ioFormat.mBytesPerPacket = 2 // sizeof int16
            ioFormat.mFramesPerPacket = 1
            
            ioFormat.mChannelsPerFrame = 1
            ioFormat.mBitsPerChannel = 16 // 8 * bytesPerSample // old 16
            
            ioFormat.mBytesPerFrame = 2 // samplesPerFrame * bytesPerSample
            
            try XExceptionIfError(AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Output), 1, &ioFormat, SizeOf32(ioFormat)), "couldn't set the input client format on AURemoteIO")
            try XExceptionIfError(AudioUnitSetProperty(self._rioUnit!, AudioUnitPropertyID(kAudioUnitProperty_StreamFormat), AudioUnitScope(kAudioUnitScope_Input), 0, &ioFormat, SizeOf32(ioFormat)), "couldn't set the output client format on AURemoteIO")
            
            var renderCallback = AURenderCallbackStruct(
                inputProc: renderingCallback,
                inputProcRefCon: Unmanaged.passUnretained(self).toOpaque()
            )
            try XExceptionIfError(AudioUnitSetProperty(
                self._rioUnit!,
                kAudioUnitProperty_SetRenderCallback,
                kAudioUnitScope_Global,
                0,
                &renderCallback,
                MemoryLayout<AURenderCallbackStruct>.size.ui),
                                  "couldn't set rend23er callback on AURemoteIO")
            
            // set the record callback
            var recordCallback = AURenderCallbackStruct(
                inputProc: recordingCallback,
                inputProcRefCon: nil
            )
            try XExceptionIfError(AudioUnitSetProperty(self._rioUnit!, kAudioOutputUnitProperty_SetInputCallback, kAudioUnitScope_Global, 1, &recordCallback, UInt32(MemoryLayout<AURenderCallbackStruct>.size)), "couldn't set record callback on AURemoteIO")
            
            var flag: UInt32 = 1
            try XExceptionIfError(AudioUnitSetProperty(self._rioUnit!, kAudioUnitProperty_ShouldAllocateBuffer, kAudioUnitScope_Output, 1, &flag, SizeOf32(flag)), "couldn't disable allocate buffer")
            
            // Initialize the AURemoteIO instance
            try XExceptionIfError(AudioUnitInitialize(self._rioUnit!), "couldn't initialize AURemoteIO instance")
        } catch let e as CAXException {
            NSLog("Error returned from setupIOUnit: %d: %@", e.mError, e.mOperation)
        } catch _ {
            NSLog("Unknown error returned from setupIOUnit")
        }
        
    }
    
    private func setupAudioChain() {
        self.setupAudioSession()
        self.setupIOUnit()
        // self.createButtonPressedSound()
    }
    
    @discardableResult
    func startIOUnit() -> OSStatus {
        let err = AudioOutputUnitStart(_rioUnit!)
        if err != 0 {NSLog("couldn't start AURemoteIO: %d", Int32(err))}
        return err
    }
    
    @discardableResult
    func stopIOUnit() -> OSStatus {
        let err = AudioOutputUnitStop(_rioUnit!)
        if err != 0 {NSLog("couldn't stop AURemoteIO: %d", Int32(err))}
        return err
    }
    
    var sessionSampleRate: Double {
        return AVAudioSession.sharedInstance().sampleRate
    }
    
}

func renderingCallback(
    inRefCon:UnsafeMutableRawPointer,
    ioActionFlags:UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp:UnsafePointer<AudioTimeStamp>,
    inBufNumber:UInt32,
    inNumberFrames:UInt32,
    ioData:UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    
    let THIS: AudioController = AudioController.sharedInstance!
    let ioPtr = UnsafeMutableAudioBufferListPointer(ioData)
    
    var availabeBytes: CInt = CInt()
    var size: UInt32
    var temp: UnsafeMutableRawPointer? = nil
    
    
    temp = TPCircularBufferTail(&THIS.receivedPCMBuffer, &availabeBytes)
    if temp == nil {
        return 1
    }

    size = min((ioPtr?[0].mDataByteSize)!, UInt32(availabeBytes))
    if size == 0 {
        return 1
    }

    memcpy( ioPtr?[0].mData, temp, Int(size))
    TPCircularBufferConsume(&THIS.receivedPCMBuffer, Int32(size))
    
    return noErr
}

func recordingCallback(
    inRefCon:UnsafeMutableRawPointer,
    ioActionFlags:UnsafeMutablePointer<AudioUnitRenderActionFlags>,
    inTimeStamp:UnsafePointer<AudioTimeStamp>,
    inBusNumber:UInt32,
    inNumberFrames:UInt32,
    ioData:UnsafeMutablePointer<AudioBufferList>?) -> OSStatus {
    //    let THIS: AudioController = AudioController.sharedInstance!
    var status = noErr
    
    let channelCount : UInt32 = 1
    
    var bufferList = AudioBufferList()
    bufferList.mNumberBuffers = channelCount
    let buffers = UnsafeMutableBufferPointer<AudioBuffer>(start: &bufferList.mBuffers,
                                                          count: Int(bufferList.mNumberBuffers))
    buffers[0].mNumberChannels = 1
    buffers[0].mDataByteSize = inNumberFrames * 2
    buffers[0].mData = malloc(Int(inNumberFrames) * 2)
    
    
    //    status = AudioUnitRender(AudioController.sharedInstance!._rioUnit!, ioActionFlags, inTimeStamp, 1, inNumberFrames, UnsafeMutablePointer<AudioBufferList>(&bufferList))
    
    status = AudioUnitRender(AudioController.sharedInstance!._rioUnit!, ioActionFlags, inTimeStamp, 1, inNumberFrames, UnsafeMutablePointer<AudioBufferList>(&bufferList))
    
    let data = Data(bytes: buffers[0].mData!, count: Int(buffers[0].mDataByteSize))
    // let audioString = data.base64EncodedString()
    //    / DispatchQueue.global(qos: .background).async {
    
    Call.sharedInstance.voiceData(channelUrl: "1118", audio: data)
    
    free(bufferList.mBuffers.mData)
    return status

}
