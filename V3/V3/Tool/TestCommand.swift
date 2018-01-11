//
//  TestCommand.swift
//  V3
//
//  Created by Anonymous on 2017/12/21.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import Foundation

public enum TestCommand {
    public enum BoardAssert: UInt8 {
        case startTestBoard         = 0x50
        case sendBrainSuccessful    = 0x51
        case chargingCurrent        = 0x52
        case chargedCurrent         = 0x53
        case rightVoltage           = 0x54
        case chargingSuccess        = 0x55
        case chargedSuccess         = 0x56
        case chargeFail             = 0x57
        case ADV                    = 0x58
        case boardConnectFixtool    = 0x59
    }

    public enum FixtureToolAssert: UInt8 {
        case AppConfiguration       = 0x31
        case SN                     = 0x32
        case UserID                 = 0x33
        case press                  = 0x34
    }

    public enum Log: UInt8 {
        case boardIntoFactoryMode   = 0x10
        case boardCharging          = 0x11
        case boardCharged           = 0x12
        case boardChargingFail      = 0x13
        case boardChargedFail       = 0x14
        case boardConnectedApp      = 0x15
        case toolToBoardCharging    = 0x21
        case toolToBoardCharged     = 0x22
    }

    public enum BoardWriteType: UInt8 {
        case AppConfigurationHeader = 0x41
        case SNHeader               = 0x42
        case deleteUserID           = 0x43
        case LED                    = 0x44
        case shutDown               = 0x45
        case startSample            = 0x01
        case stopSample             = 0x02
    }

    public enum FixtureToolType: UInt8 {
        case contactSingal          = 0x61
        case powerOff               = 0x62
    }
}

