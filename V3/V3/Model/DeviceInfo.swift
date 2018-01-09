//
//  DeviceInfo.swift
//  V3
//
//  Created by Anonymous on 2017/12/28.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

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
        }
    }
    var productdDate: String {
        get {
            if let value = Defaults[.productedDate] {
                return value
            } else {
                // TODO:
                return "171226"
            }
        }
        set {
            Defaults[.productedDate] = newValue
        }
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
        }
    }

    private init() {}
    public static let shared = DeviceInfo()
}
