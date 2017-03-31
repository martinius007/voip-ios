//
//  AppDelegate.swift
//  voip-ios
//
//  Created by Timur Nutfullin on 31/03/2017.
//  Copyright © 2017 tim notfoolen. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    class var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }
    
    var window: UIWindow?
    let callManager = CallManager()


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        AppSocket.closeConnection()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        DispatchQueue.global(qos: .userInitiated).async {
            if !AppSocket.isConnected() {
                let url = Config.getWSUrl()
                AppSocket.establishConnection(url) { (socket, connected) in
                    guard connected else {
                        // guard let response = AppSocketResponse(
                        guard let _ = AppSocketResponse(
                            "Can't connect to the socket" as AnyObject,
                            socket: socket
                            ) else { return }
                        return
                    }
                }
            }
        }
    }

    func applicationWillTerminate(_ application: UIApplication) {
    }

}

