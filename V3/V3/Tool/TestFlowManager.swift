//
//  TestFlowManager.swift
//  V3
//
//  Created by Anonymous on 2017/12/20.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import Foundation
import RxBluetoothKit
import RxSwift
import NaptimeBLE
import PromiseKit
import SwiftyTimer
import SVProgressHUD

let TESTBOARD_ADV_LENGTH   = 2
let RAWBRAIN_SAMPLE_LENGTH = 750
let BRAINVALUE_RANGE_MIN   = 0x7F8A7C
let BRAINVALUE_RANGE_MAX   = 0xBF683E


public enum TestFlowState: String {
    case ReadyTest             = "ReadyTest"
    case StartTest             = "StartTest"
    case BoardChargePass       = "BoardChargePass"
    case BoardConnectedApp     = "BoardConnectedApp"
    case BrainAnalysePass      = "BrainAnalysePass"
    case EggContactCheckPass   = "EggContactCheckPass"
    case BoardDisConnectFixtool   = "BoardDIsConnectFixtool"
    case BoardRightVoltagePass = "BoardRightVoltagePass"
    case LEDDeviceReply        = "LEDDeviceReply"
//    case BurnIntoDevicedIDPass = "BurnIntoDevicedIDPass"
    case Completed             = "Completed"
    case TestFail              = "TestFail"
    case BoardAborted          = "BoardAborted"
    case FixToolAborted        = "FixToolAborted"
}


class TestFlowManager {
    private let toolManager: BluetoothManager

    public var state: Variable<TestFlowState>
    private var fixtureTool: Peripheral?
    private var testedBoard: Peripheral?
    private var fixtureToolConnector: Connector?
    private var testedBoardConnector: Connector?
    private let scanner        = NaptimeBLE.Scanner()
    private let _disposeBag    = DisposeBag()

    public init() {
        toolManager = BluetoothManager(queue: .main, options: nil)
        self.state = Variable(.ReadyTest)
    }
    // 搜索设备
    func scan() -> Observable<ScannedPeripheral> {
        return scanner.scan()
    }
    func stopScan() {
        self.scanner.stop()
    }

    // 连接蓝牙设备
    func connectWith(peripheral: Peripheral) {
        if self.state.value == .ReadyTest {
            self.fixtureToolConnector = Connector(peripheral: peripheral)
            self.fixtureTool          = peripheral
            self.fixtureToolConnector!.tryConnect().then(execute: { () -> Void in
                Logger.shared.log(message: "fixtool_connect app success", lavel: .Show)
                self.listenFixtureToolIsConnected()
                Thread.sleep(forTimeInterval: 0.1)
                self.setFixtureToolNotify()
            }).catch(execute: { (error) in
                Logger.shared.log(message: "fixtool_connect app failed", lavel: .Error)
            })
        } else {
            self.testedBoardConnector = Connector(peripheral: peripheral)
            self.testedBoard          = peripheral
            self.testedBoardConnector!.tryConnect().then { () -> Void in
                guard TestFlowState.BoardChargePass == self.state.value else {
                    self.state.value = TestFlowState.TestFail
                    return
                }
                Logger.shared.log(message: "testing_board connect app connect success", lavel: .Show)
                self.state.value = TestFlowState.BoardConnectedApp
                self.setBoardNotify()
                Thread.sleep(forTimeInterval: 0.1)
                self.startEggSampleNotify()
                Thread.sleep(forTimeInterval: 0.1)
                self.startEggContactNotify()
                Thread.sleep(forTimeInterval: 0.1)
                self.startSample().then(execute: { () -> () in
                    Logger.shared.log(message: "send 0x01 start sample", lavel: .Show)
                }).catch(execute: { (error) in
                    self.state.value = TestFlowState.TestFail
                    Logger.shared.log(message: "start smaple failed", lavel: .Error)
                    print(error)
                })
                }.catch(execute: { (error) in
                    self.state.value = TestFlowState.TestFail
                    Logger.shared.log(message: "test_borad connect app failed", lavel: .Error)
                    print(error)
                })
        }
    }

    // 单板：发送 LED 测试
    private func startBoardLEDTest() -> Promise<Void> {
        return (self.testedBoardConnector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.LED.rawValue]), to: Characteristic.Command.Write.send))!
    }

    // 单板：关机
    func shutdownBoard() -> Promise<Void> {
        return (self.testedBoardConnector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.shutDown.rawValue]), to: Characteristic.Command.Write.send))!
    }

    // 工装: 开始脱落信息
    private func startContactSignal() -> Promise<Void> {
        return (self.fixtureToolConnector?.commandService?.write(data: Data(bytes: [0x61]), to: Characteristic.Command.Write.send))!
    }

    // 工装：停止向板子充电
    private func stopCharging() -> Promise<Void> {
//        self.state.value = TestFlowState.Completed
        return (self.fixtureToolConnector?.commandService?.write(data: Data(bytes: [TestCommand.FixtureToolType.powerOff.rawValue]), to: Characteristic.Command.Write.send))!
    }

    // 开始采集
    private func startSample() -> Promise<Void> {
        return (self.testedBoardConnector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.startSample.rawValue]), to: Characteristic.Command.Write.send))!
    }

    func stopTest() {
        self.stopCharging().then { () -> () in
            self.boardScanDisposeBag?.dispose()
            self.boardPressDisposeBag?.dispose()
            self.boardEegDisposeBag?.dispose()
            self.boardContactDisposeBag?.dispose()
            if let connect = self.testedBoardConnector {
                connect.cancel()
                connect.peripheral.cancelConnection().subscribe().dispose()
            }
            self.testInitial()
        }
    }

    func cancelConnection() {
        self.fixtureToolConnector?.peripheral.cancelConnection().subscribe {
            self.cleanUp()
        }.disposed(by: self._disposeBag)
    }

    private func testInitial() {
        self.testedBoard = nil
        self.testedBoardConnector = nil
        self.boardScanDisposeBag = nil
        self.boardPressDisposeBag = nil
        self.boardEegDisposeBag = nil
        self.boardContactDisposeBag = nil

        self.state.value = TestFlowState.ReadyTest
        self.tempADV = [UInt8]()
        self.hasBrainSampleTested = false
        self.currentBrainSmaples = [UInt8]()
        self.contactSequence = [UInt8]()
        self.hasContactTested = false
        self.hasBrainPass = true
    }

    private func cleanUp() {
        if let connect = self.fixtureToolConnector {
            connect.cancel()
            connect.peripheral.cancelConnection().subscribe().dispose()
        }
        self.fixtoolDisposeBag?.dispose()
        self.fixtoolDisposeBag = nil
        self.stopTest()
    }

    // 停止采集
    private func stopSample() -> Promise<Void> {
        return (self.testedBoardConnector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.stopSample.rawValue]), to: Characteristic.Command.Write.send))!
    }

    private var tempADV = [UInt8]()

    private var hasRightVoltagePass = false
    private var boardScanDisposeBag: Disposable?
    private var fixtoolDisposeBag: Disposable?
    // 设置工装监听
    private func setFixtureToolNotify() {
        self.fixtoolDisposeBag = self.fixtureToolConnector?.commandService?.notify(characteristic: Characteristic.Command.Notify.receive)
            .subscribe (onNext: { [weak self] in
                guard let `self` = self else { return }

                Logger.shared.log(message: "fixtool_signal -- \($0)", lavel: .Debug)
                if let type = TestCommand.BoardAssert(rawValue: $0.first!) {
                    switch type {
                    case TestCommand.BoardAssert.startTestBoard:
                        if self.state.value == TestFlowState.ReadyTest {
                            self.state.value = TestFlowState.StartTest
                        }
                        break
                    case TestCommand.BoardAssert.sendBrainSuccessful:
                        break
                    case TestCommand.BoardAssert.chargingCurrent:
                        var temp = $0
                        temp.removeFirst(1)
                        if let v = temp.first, !(v >= 0x32 && v <= 0x3c) {
                            self.state.value = TestFlowState.TestFail
                        }
                        break
                    case TestCommand.BoardAssert.chargedCurrent:
                        var temp = $0
                        temp.removeFirst(1)
                        if let eleticty = temp.first, !(eleticty >= 0x00 && eleticty <= 0x05) {
                            self.state.value = TestFlowState.TestFail
                        }
                        break
                    case TestCommand.BoardAssert.rightVoltage:
                        var temp = $0
                        temp.removeFirst(1)
                        if let voltage = temp.first, (voltage >= 29 && voltage <= 31) {
                            self.hasRightVoltagePass = true
                        }
                        break
                    case TestCommand.BoardAssert.chargingSuccess: break
                    case TestCommand.BoardAssert.chargedSuccess:
                        guard TestFlowState.StartTest == self.state.value else {
                            self.state.value = TestFlowState.TestFail
                            return
                        }
                        self.state.value = TestFlowState.BoardChargePass
                        if self.tempADV.count > 0 {
                            self.boardScanDisposeBag = self.scan().subscribe { [weak self] in
                                guard let `self` = self else { return }
                                if let mData = $0.element?.advertisementData.manufacturerData {
                                    var temp = mData
                                    temp.removeFirst(2)
                                    let ADV = Data(bytes: self.tempADV)
                                    if temp == ADV {
                                        self.testedBoardConnector = Connector(peripheral: $0.element!.peripheral)
                                        self.connectWith(peripheral: $0.element!.peripheral)
                                    }
                                }}
                        }
                        break
                    case TestCommand.BoardAssert.chargeFail:
                        self.state.value = TestFlowState.TestFail
                        break
                    case TestCommand.BoardAssert.ADV:
                        var testedBoardADV = $0
                        testedBoardADV.removeFirst(1)
                        self.tempADV = testedBoardADV
                        if self.state.value == TestFlowState.BoardChargePass {
                            self.boardScanDisposeBag = self.scan().subscribe { [weak self] in
                                guard let `self` = self else { return }
                                if let mData = $0.element?.advertisementData.manufacturerData {
                                    var temp = mData
                                    temp.removeFirst(2)
                                    let ADV = Data(bytes: self.tempADV)
                                    if temp == ADV {
                                        self.testedBoardConnector = Connector(peripheral: $0.element!.peripheral)
                                        self.connectWith(peripheral: $0.element!.peripheral)
                                    }
                                }}
                        }
                        break
                    case TestCommand.BoardAssert.boardDisConnectFixtool:
                        self.state.value = TestFlowState.BoardDisConnectFixtool
                        self.timer?.invalidate()
                        self.timer = nil
                        self.stopTest()
                        break
                    }
                }
            })
    }

    private var boardCommandDispose: Disposable?

    private var boardPressDisposeBag: Disposable?
    // 设置板子监听
    private func setBoardNotify() {
        self.boardPressDisposeBag = self.testedBoardConnector?.commandService?.notify(characteristic: Characteristic.Command.Notify.receive)
            .subscribe (onNext: { [weak self] in
                guard let `self` = self else { return }
//                print("testing_board - \(Date())-\($0)")
                Logger.shared.log(message: "硬件按键反馈 -- \($0)", lavel: .Show)
                if let type = TestCommand.FixtureToolAssert(rawValue: $0.first!) {
                    switch type {
                    case TestCommand.FixtureToolAssert.press:
                        self.state.value = TestFlowState.Completed
                        break
                    default: break
                    }
                }
            })
    }

    private var currentBrainSmaples = [UInt8]()
    private var hasBrainSampleTested = false

    private var boardEegDisposeBag: Disposable?
    private var timer: Timer?
    private var hasBrainPass = true
    // 设置单板监听。
    private func startEggSampleNotify() {
        self.boardEegDisposeBag = self.testedBoardConnector?.eegService!.notify(characteristic: Characteristic.EEG.Notify.data)
            .subscribe (onNext: { [weak self] in
                guard let `self` = self else { return }
                // ugly code
                if self.currentBrainSmaples.count >= RAWBRAIN_SAMPLE_LENGTH {
                    if self.hasBrainSampleTested { return }

                    self.hasBrainSampleTested = true
                    for index in  0..<self.currentBrainSmaples.count {
                        if (index + 1) % 3 == 0 {
                            let brainValue1 = Int32(self.currentBrainSmaples[index-1]) << 8
                            let brainValue2 = Int32(self.currentBrainSmaples[index-2]) << 16
                            let brainValue = Int32(self.currentBrainSmaples[index]) + brainValue1 + brainValue2
                            if brainValue > BRAINVALUE_RANGE_MIN && brainValue < BRAINVALUE_RANGE_MAX {
                                Logger.shared.log(message: "脑波分析：\(brainValue)", lavel: .Show)
                                continue
                            } else {
                                Logger.shared.log(message: "Out of Range \(brainValue)", lavel: .Error)
                                self.hasBrainPass = false
                                continue
//                                return
                            }
                        }
                    }
                    if !self.hasBrainPass {
                        self.state.value = TestFlowState.TestFail
                        return
                    }
                    if self.state.value == TestFlowState.BoardConnectedApp {
                        self.state.value = TestFlowState.BrainAnalysePass
//                        print("brain test pass .......")
                        Logger.shared.log(message: "脑波分析通过", lavel: .Show)
                        self.startContactSignal().then(execute: { () -> () in
//                            print("start contact singnal \(TestCommand.FixtureToolType.contactSingal.rawValue)")
                            Logger.shared.log(message: "开始脱落信号", lavel: .Error)
                            self.timer = Timer.after(4) {
                                if !self.hasContactTested {
                                    self.hasContactTested = true
                                    // 使用 dispatch_after 有风险，block 执行不是在当前队列延迟操作的。
                                    self.contactTest()
                                }
                            }
                        })
                    } else {
                        self.state.value = TestFlowState.TestFail
                    }
                } else {
                    var sample = $0
                    sample.removeFirst(2)
                    self.currentBrainSmaples.append(contentsOf: sample)
                }
            })
    }

    private var contactSequence = [UInt8]()
    private var hasContactTested = false
    private var boardContactDisposeBag: Disposable?

    // 开始脱落检测监听
    private func startEggContactNotify() {
       self.boardContactDisposeBag = self.testedBoardConnector?.eegService!.notify(characteristic: Characteristic.EEG.Notify.contact)
            .subscribe (onNext: { [weak self] in
                guard let `self` = self else { return }
//                print("testing_board: egg contact \(Date())-\($0)")
                Logger.shared.log(message: "脱落信号检测 -- \($0)", lavel: .Show)
                self.contactSequence.append(contentsOf: $0)
            })
    }

    // 监听工装是否断开
    private func listenFixtureToolIsConnected() {
        self.fixtureTool?.rx_isConnected
            .subscribe { [weak self] in
                guard let `self` = self else { return }
                if !$0.element! {
                    self.state.value = TestFlowState.FixToolAborted
                    self.cleanUp()
                }
            }.disposed(by: _disposeBag)
    }

    // 脱落检测测试
    private func contactTest() {
        guard  let _ = self.testedBoardConnector else { return }
        self.stopSample().then(execute: { () -> () in
            if contains(self.contactSequence, [8, 16, 24, 0]) {
                if self.state.value == TestFlowState.BrainAnalysePass {
                    self.state.value = TestFlowState.EggContactCheckPass
                    if self.hasRightVoltagePass {
                        if self.state.value == .EggContactCheckPass {
                            Logger.shared.log(message: "右腿电压测试通过", lavel: .Show)
                            self.state.value = TestFlowState.BoardRightVoltagePass
                            self.state.value = TestFlowState.LEDDeviceReply
                        }
                    } else {
                        Logger.shared.log(message: "右腿电压测试不通过", lavel: .Error)
                        self.state.value = TestFlowState.TestFail
                    }
                    self.startBoardLEDTest().then(execute: { ()->(Void) in
                        Logger.shared.log(message: "LED 灯测试", lavel: .Show)
                    }).catch(execute: { (error) in
                        print(error)
                        Logger.shared.log(message: "写入 LED 灯信号失败", lavel: .Error)
                        self.state.value = TestFlowState.TestFail
                    })
                } else {
                    self.state.value = TestFlowState.TestFail
                    Logger.shared.log(message: "内部状态逻辑错误", lavel: .Error)
                }
            } else {
                self.state.value = TestFlowState.TestFail
                Logger.shared.log(message: "脱落信号测试不通过", lavel: .Error)
            }
        }).catch(execute: {(error) in
            print(error)
        })
    }
}
