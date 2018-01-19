//
//  Comnon.swift
//  V3
//
//  Created by Anonymous on 2017/12/26.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import Foundation

// TODO: 还没有完成的 ugly code
public func contains(_ sequence: [UInt8], _ subSequence: [UInt8]) -> Bool {
    if sequence.count >= subSequence.count {
        for i in 0..<sequence.count {
            for j in 0..<subSequence.count {
                if (i + j) >= sequence.count {
                    print(i + subSequence.count)
                    print(sequence.count)
                    return false
                } else if sequence[i+j] == subSequence[j] {
                    if j == (subSequence.count - 1) {
                        return true
                    }
                    continue
                } else {
                    break
                }
            }
        }
    }
    return false
}


extension Date {
    public func stringWith(dateFormatterString: String)-> String {
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormatterString
        return formatter.string(from: self)
    }
}
