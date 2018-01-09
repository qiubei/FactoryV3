//
//  GCD.swift
//  V3
//
//  Created by Anonymous on 2017/12/23.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import Foundation

typealias DispatchBlock = () -> Void

func dispatch_to_main(_ block: @escaping DispatchBlock) {
    if Thread.isMainThread {
        block()
    } else {
        DispatchQueue.main.async {
            block ()
        }
    }
}

func dispatch_after(_ time: UInt64, _ block: @escaping DispatchBlock) {
    let time = DispatchTime(uptimeNanoseconds: time * NSEC_PER_SEC)
    DispatchQueue.main.asyncAfter(deadline: time) {
        block()
    }
}
