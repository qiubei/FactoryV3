//
//  FixtureTool.swift
//  V3
//
//  Created by Anonymous on 2017/12/20.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import Foundation
import RxBluetoothKit
import RxSwift
import NaptimeBLE

class FixtureToolPeriprheral {
    let peripheral: Peripheral
    init(peripheral: Peripheral) {
        self.peripheral = peripheral
    }
}
