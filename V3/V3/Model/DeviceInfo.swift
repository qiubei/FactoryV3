//
//  DeviceInfo.swift
//  V3
//
//  Created by Anonymous on 2017/12/28.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

extension DefaultsKey {
    public var notificationName: Notification.Name {
        let notification = Notification.Name(self._key + "NotificatonName")
        return notification
    }
}

class DeviceInfo {
    var hardwareVersion: String {
        get {
            if let value = Defaults[.hardwareVersion] {
                return value
            } else {
                return "300"
            }
        }
        set {
            Defaults[.hardwareVersion] = newValue
            NotificationCenter.default.post(name: DefaultsKeys.hardwareVersion.notificationName, object: nil)
        }
    }
    var distributor: String {
        get {
            if let value = Defaults[.distributor] {
                return value
            } else {
                return "000"
            }
        }
        set {
            Defaults[.distributor] = newValue
            NotificationCenter.default.post(name: DefaultsKeys.distributor.notificationName, object: nil)
        }
    }
    var customMade: String {
        get {
            if let value = Defaults[.customMade] {
                return value
            } else {
                return "00"
            }
        }
        set {
            Defaults[.customMade] = newValue
            NotificationCenter.default.post(name: DefaultsKeys.customMade.notificationName, object: nil)
        }
    }
    var production: String {
        get {
            if let value = Defaults[.production] {
                return value
            } else {
                return "00"
            }
        }
        set {
            Defaults[.production] = newValue
            NotificationCenter.default.post(name: DefaultsKeys.production.notificationName, object: nil)
        }
    }
    var productdDate: String {
        return Date().stringWith(dateFormatterString: "yyMMdd")
    }

    var snCode: String {
        get {
            if let value = Defaults[.snCode] {
                return value
            } else {
                return "0000000000000000"
            }
        }
        set {
            Defaults[.snCode] = newValue
            NotificationCenter.default.post(name: DefaultsKeys.snCode.notificationName, object: nil)
        }
    }

    private init() {}
    public static let shared = DeviceInfo()
}
