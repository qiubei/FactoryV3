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
    case LEDShining            = "LEDShining"
    case LEDDeviceReply        = "LEDDeviceReply"
    case BurnIntoDevicedIDPass = "BurnIntoDevicedIDPass"
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
                self.listenFixtureToolIsConnected()
                Thread.sleep(forTimeInterval: 0.1)
                self.setFixtureToolNotify()
            }).catch(execute: { (error) in
                print(error)
            })
        } else {
            self.testedBoardConnector = Connector(peripheral: peripheral)
            self.testedBoard          = peripheral
            self.testedBoardConnector!.tryConnect().then { () -> Void in
                self.state.value = TestFlowState.BoardConnectedApp
                self.listTestedBoardIsConnected()
                Thread.sleep(forTimeInterval: 0.1)
                self.setBoardNotify()
                Thread.sleep(forTimeInterval: 0.1)
                self.startEggSampleNotify()
                Thread.sleep(forTimeInterval: 0.1)
                self.startEggContactNotify()
                Thread.sleep(forTimeInterval: 0.1)
                self.startSample().then(execute: { () -> () in
                    SVProgressHUD.showSuccess(withStatus: "0x01")
                    print("send start sample")
                }).catch(execute: { (error) in
                    self.state.value = TestFlowState.TestFail
                    print(error)
                })
                }.catch(execute: { (error) in
                    self.state.value = TestFlowState.TestFail
                    print(error)
                })
        }
    }

    // 单板：发送 LED 测试
    func startBoardLEDTest() -> Promise<Void> {
        return (self.testedBoardConnector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.LED.rawValue]), to: Characteristic.Command.Write.send))!
    }

    // 单板：关机
    func shutdownBoard() -> Promise<Void> {
        return (self.testedBoardConnector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.shutDown.rawValue]), to: Characteristic.Command.Write.send))!
    }

    // 工装: 开始脱落信息
    func startContactSignal() -> Promise<Void> {
        return (self.fixtureToolConnector?.commandService?.write(data: Data(bytes: [0x61]), to: Characteristic.Command.Write.send))!
    }

    // 工装：停止向板子充电
    func stopCharging() -> Promise<Void> {
//        self.state.value = TestFlowState.Completed
        return (self.fixtureToolConnector?.commandService?.write(data: Data(bytes: [TestCommand.FixtureToolType.powerOff.rawValue]), to: Characteristic.Command.Write.send))!
    }

    // 开始采集
    func startSample() -> Promise<Void> {
        return (self.testedBoardConnector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.startSample.rawValue]), to: Characteristic.Command.Write.send))!
    }

    func stopTest() {
        self.stopCharging().then { () -> () in
            self.testedBoard?.cancelConnection().subscribe().disposed(by: self._disposeBag)
            self.testedBoard = nil
            self.hasContactTested = false
            self.hasBrainSampleTested = false
        }
    }

    func cancelConnection() {
        self.fixtureToolConnector?.peripheral.cancelConnection().subscribe {
            self.fixtureTool = nil
            self.testedBoard = nil
            self.fixtureToolConnector = nil
            self.testedBoardConnector = nil
        }.disposed(by: self._disposeBag)
    }

    func restart() {
        
    }

    func cleanUp() {
        self.state.value = .ReadyTest
        self.testedBoard = nil
        self.hasContactTested = false
        self.hasBrainSampleTested = false
    }

    // 停止采集
    private func stopSmaple() -> Promise<Void> {
        return (self.testedBoardConnector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.stopSample.rawValue]), to: Characteristic.Command.Write.send))!
    }

    private var tempADV = [UInt8]()

    // 设置工装监听
    private func setFixtureToolNotify() {
        self.fixtureToolConnector?.commandService?.notify(characteristic: Characteristic.Command.Notify.receive)
            .subscribe (onNext: { [weak self] in
                guard let `self` = self else { return }

                print("fixture_tool - \(Date())-\($0)")
                if let type = TestCommand.BoardAssert(rawValue: $0.first!) {
                    switch type {
                    case TestCommand.BoardAssert.startTestBoard:
                        self.state.value = TestFlowState.StartTest
                        break
                    case TestCommand.BoardAssert.sendBrainSuccessful:
                        break
                    case TestCommand.BoardAssert.chargingCurrent: break
                    case TestCommand.BoardAssert.chargedCurrent: break
                    case TestCommand.BoardAssert.rightVoltage: break
                    case TestCommand.BoardAssert.chargingSuccess: break
                    case TestCommand.BoardAssert.chargedSuccess:
                        self.state.value = TestFlowState.BoardChargePass

                        if self.tempADV.count > 0 {
                            self.scan().subscribe { [weak self] in
                                guard let `self` = self else { return }
                                if let mData = $0.element?.advertisementData.manufacturerData {
                                    print("mData - \(mData.copiedBytes)")
                                    var temp = mData
                                    temp.removeFirst(2)
                                    let ADV = Data(bytes: self.tempADV)
                                    if temp == ADV {
                                        self.testedBoardConnector = Connector(peripheral: $0.element!.peripheral)
                                        self.connectWith(peripheral: $0.element!.peripheral)
                                    }
                                }}.disposed( by: self._disposeBag)
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
                            self.scan().subscribe { [weak self] in
                                guard let `self` = self else { return }
                                if let mData = $0.element?.advertisementData.manufacturerData {
                                    print("mData - \(mData.copiedBytes)")
                                    var temp = mData
                                    temp.removeFirst(2)
                                    let ADV = Data(bytes: self.tempADV)
                                    if temp == ADV {
                                        self.testedBoardConnector = Connector(peripheral: $0.element!.peripheral)
                                        self.connectWith(peripheral: $0.element!.peripheral)
                                    }
                                }}.disposed( by: self._disposeBag)
                        }
                    }
                }
            }).disposed(by: _disposeBag)
    }

    private var hasAppConfigureDataTestPass = false
    private var hasSNCodeTestPass = false
    private var hasDeleteUesrIDTestPass = false


    private var boardCommandDispose: Disposable?
    // 设置板子监听
    private func setBoardNotify() {
        self.testedBoardConnector?.commandService?.notify(characteristic: Characteristic.Command.Notify.receive)
            .subscribe (onNext: { [weak self] in
                guard let `self` = self else { return }
                print("tested_board - \(Date())-\($0)")
                if let type = TestCommand.FixtureToolAssert(rawValue: $0.first!) {
                    switch type {
                    case TestCommand.FixtureToolAssert.press:
                        self.state.value = TestFlowState.LEDDeviceReply
                        self.state.value = TestFlowState.Completed
                        break
                    default: break
                    }
                }
            }).disposed(by: self._disposeBag)
    }

    private var currentBrainSmaples = [UInt8]()
    private var hasBrainSampleTested = false

    // 设置单板监听。
    private func startEggSampleNotify() {
        self.testedBoardConnector?.eegService!.notify(characteristic: Characteristic.EEG.Notify.data)
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
                            print("\(BRAINVALUE_RANGE_MIN) - \(brainValue) - \(BRAINVALUE_RANGE_MAX)")
                            if brainValue > BRAINVALUE_RANGE_MIN && brainValue < BRAINVALUE_RANGE_MAX {
                                continue
                            } else {
                                self.state.value = TestFlowState.TestFail
                                return
                            }
                        }
                    }
                    self.state.value = TestFlowState.BrainAnalysePass
                    print("brain test pass .......")
                    self.startContactSignal().then(execute: { () -> () in
                        print("start contact singnal \(TestCommand.FixtureToolType.contactSingal.rawValue)")
                        Timer.after(4) {
                            if !self.hasContactTested {
                                self.hasContactTested = true
                                // 使用 dispatch_after 有风险，block 执行不是在当前队列延迟操作的。
                                self.contactTest()
                            }
                        }
                    })
                } else {
                    var sample = $0
                    sample.removeFirst(2)
                    self.currentBrainSmaples.append(contentsOf: sample)
                }
            }).disposed(by: _disposeBag)
    }

    private var contactSequence = [UInt8]()
    private var hasContactTested = false


    // 开始脱落检测监听
    private func startEggContactNotify() {
        self.testedBoardConnector?.eegService!.notify(characteristic: Characteristic.EEG.Notify.contact)
            .subscribe (onNext: { [weak self] in
                guard let `self` = self else { return }
                print("tested_board: egg contact \(Date())-\($0)")
                self.contactSequence.append(contentsOf: $0)
            }).disposed(by: _disposeBag)
    }

    // 监听工装是否断开
    private func listenFixtureToolIsConnected() {
        self.fixtureTool?.rx_isConnected
            .subscribe { [weak self] in
                guard let `self` = self else { return }
                if !$0.element! {
                    self.state.value = TestFlowState.FixToolAborted
                }
            }.disposed(by: _disposeBag)
    }

    // 监听板子是否断开
    private func listTestedBoardIsConnected() {
        self.testedBoard?.rx_isConnected
            .subscribe { [weak self] in
                guard let `self` = self else { return }
                if !$0.element! {
                    self.state.value = TestFlowState.BoardAborted
                }
            }.disposed(by: _disposeBag)
    }

    // 脱落检测测试
    private func contactTest() {
        if contains(self.contactSequence, [8, 16, 24]) {
            self.state.value = TestFlowState.EggContactCheckPass
            self.stopSmaple().then(execute: { () -> () in
                self.startBoardLEDTest().then(execute: { ()->(Void) in
                    self.state.value = TestFlowState.LEDShining
                }).catch(execute: { (error) in
                    print(error)
                    self.state.value = TestFlowState.TestFail
                })
            }).catch(execute: {(error) in
                print(error)
            })
        } else {
            self.state.value = TestFlowState.TestFail
        }
    }
}
