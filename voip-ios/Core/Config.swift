//
//  Config.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import Foundation
import EVReflection

class Config {
    
    public static let APP_NAME = "VOIP-IOS"
    
    // Network
    
    public static let PUBLIC_URL = "https://dev.notfoolen.ru"
    public static let SERVER_ADDR_API = "https://dev.notfoolen.ru/api/"
    
    public static func getWSUrl() -> URL {
        return URL(string: "https://dev.notfoolen.ru:5557")!
    }
    
}
