//
//  Call.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation

class Call {
    
    static var sharedInstance: Call = Call()
    private var receivedPCMBuffer: TPCircularBuffer = TPCircularBuffer()
    var g729EncoderDecoder: G729Wrapper!
    //    private var opusEncoder = CSIOpusEncoder(sampleRate: opus_int32(AudioController.sampleRate), channels: 1, frameDuration: 0.01)
    
    init() {
        TPCircularBufferInit(&self.receivedPCMBuffer, 10000000)
        g729EncoderDecoder = G729Wrapper()
        
        g729EncoderDecoder!.open()
    }
    
    func send(channelUrl: String, completion: @escaping OutgoingCall) {
        resetPCMBuffer()
        AppSocket.callSend(channelUrl: channelUrl, completion: completion)
    }
    
    func answer(channelUrl: String, completion: @escaping () -> Swift.Void) {
        resetPCMBuffer()
        AppSocket.callAnswer(channelUrl: channelUrl, completion: completion)
    }
    
    func reject(channelUrl: String, completion: @escaping () -> Swift.Void) {
        resetPCMBuffer()
        AppSocket.callReject(channelUrl: channelUrl, completion: completion)
    }
    
    func hangout(channelUrl: String, completion: @escaping () -> Swift.Void) {
        resetPCMBuffer()
        AppSocket.callHangout(channelUrl: channelUrl, completion: completion)
    }
    
    private func resetPCMBuffer() {
        TPCircularBufferClear(&self.receivedPCMBuffer)
    }
    
    let sizeEncodeBuffer = Int32(160)
    var shortArray: [CShort] = [CShort](repeating: 0, count: 80)
    
    func voiceData(channelUrl: String, audio: Data) {
        // пишем в буфер
        let nsData = audio as NSData
        var isBufferProduceBytes: CBool = false
        isBufferProduceBytes = TPCircularBufferProduceBytes(&self.receivedPCMBuffer, nsData.bytes, Int32(audio.count))
        if !isBufferProduceBytes {
        }
        var availabeBytes: CInt = CInt()
        
        let buffer: UnsafeMutableRawPointer = TPCircularBufferTail(&self.receivedPCMBuffer, &availabeBytes)
        if availabeBytes > 159 {
            
            memcpy(&shortArray, buffer, 160)
            TPCircularBufferConsume(&self.receivedPCMBuffer, 160);
            
            var g729EncodedBytes: [Byte] = Array(repeating: Byte(), count: 160)
            
            print(g729EncodedBytes)
            let encodedLength: CInt = g729EncoderDecoder.encode(withPCM: &shortArray, andSize: 80, andEncodedG729: &g729EncodedBytes)
            print(g729EncodedBytes)
            if encodedLength > 0 {
                print(160, encodedLength)
                //                audioDelegate.recordedRTP(g729EncodedBytes, andLenght: encodedLength)
                let audioString = Data(bytes: &g729EncodedBytes, count: Int(encodedLength)).base64EncodedString()
                
                print(audioString)
                AppSocket.callVoiceData(channelUrl: channelUrl, data: audioString)
            }
        }
    }
    
}
