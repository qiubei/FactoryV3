//
//  AppDelegate.swift
//  V3
//
//  Created by Anonymous on 2017/12/20.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // bugly
        Bugly.start(withAppId: "c82324a9aa")
        return true
    }
}

