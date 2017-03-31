//
//  Log.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation

final class Log {
    
    static func debug(_ text: String?) {
        guard let text = text else { return }
        
        #if DEBUG
            print(text)
        #endif
    }
    
    static func debug(_ obj: AnyObject?) {
        guard let obj = obj else { return }
        
        #if DEBUG
            print(obj)
        #endif
    }
    
    static func debug(_ error: Error?) {
        guard let error = error else { return }
        
        #if DEBUG
            print(error)
        #endif
    }
    
}
