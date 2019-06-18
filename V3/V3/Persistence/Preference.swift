//
//  Preference.swift
//  V3
//
//  Created by Anonymous on 2017/12/28.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import Foundation
import SwiftyUserDefaults

extension DefaultsKeys {
    static let hardwareVersion = DefaultsKey<String?>("hardwareVersionKey")
    static let distributor = DefaultsKey<String?>("distributor")
    static let customMade = DefaultsKey<String?>("customMade")
    static let production = DefaultsKey<String?>("production")
    static let productedDate = DefaultsKey<String?>("productedDate")
    static let snCode = DefaultsKey<String?>("snCodeKey")
}
