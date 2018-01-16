//
//  SystemTestManager.swift
//  V3
//
//  Created by Anonymous on 2018/1/4.
//  Copyright © 2018年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import Foundation
import PromiseKit
import NaptimeBLE
import RxSwift
import RxBluetoothKit
import SVProgressHUD

public enum SystemTestState: String {
    case StartTest                = "StartTest"
    case BatteryTestPass          = "BatteryTestPASS"
    case contactTestPass          = "contactTestPass"
    case contactTestFail          = "contactTestFail"
    case burnAppConfigurationPass = "burnAppConfigurationPass"
    case burnAppConfigurationFail = "burnAppConfigurationFail"
    case burnSnCodePass           = "burnSnCodePass"
    case burnSnCodeFail           = "burnSnCodeFail"
    case deleteUserIDPass         = "deleteUserIDPass"
    case deleteUserIFail          = "deleteUserIFail"
    case TestFail                 = "TestFail"
}

class SystemTestManager {
    static let shared = SystemTestManager()
    var state: Variable<SystemTestState>
    var connector: Connector?

    private var scanner = NaptimeBLE.Scanner()
    private let _disposeBag = DisposeBag()
    private init() {
        self.state = Variable(SystemTestState.StartTest)
    }

    // 搜索设备
    func scan() -> Observable<ScannedPeripheral> {
        return scanner.scan()
    }

    func stopScan() {
        return scanner.stop()
    }

    // 停止搜索设备
    func stopTest() {
        self.connector?.peripheral.cancelConnection()
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                print($0)
                self.connector?.cancel()
                self.scanner.stop()
            }).disposed(by: self._disposeBag)
        self.cleanUp()
    }

    private func cleanUp() {
        self.connector = nil
        self.snCode = Data()
        self.appConfigureData = Data()
        self.contactDisposeBag?.dispose()
        self.contactDisposeBag = nil
        self.eegDisposeBag?.dispose()
        self.eegDisposeBag = nil
        self.burnDeviceIDDispiseBag?.dispose()
        self.burnDeviceIDDispiseBag = nil
        self.state.value = SystemTestState.StartTest

        self.appConfiguration = nil
        self.sn = nil
        self.userID = nil
        self.contactValue = Variable(-1)
    }

    // 连接蓝牙设备
    func startTestWith(peripheral: Peripheral) -> Promise<Void>{
        self.connector = Connector(peripheral: peripheral)
        let promise = Promise<Void> { (fulfill, reject) in
            self.connector?.tryConnect().then(execute: { () -> () in
                self.burnDeviceNotify()
                fulfill(())
            }).catch(execute: { (error) in
                reject(error)
            })
        }
        return promise
    }

    var appConfigureData = Data()

    // 单板：烧入 app 配置项
    func burnBoardAppConfigure(appConfigureData: Data) -> Promise<Void> {
        self.appConfigureData = appConfigureData
        self.appConfigureData.insert(TestCommand.BoardWriteType.AppConfigurationHeader.rawValue, at: 0)
        return self.connector!.commandService!.write(data: self.appConfigureData, to: Characteristic.Command.Write.send)
    }

    var snCode = Data()

    // 单板：烧入 SN 码
    func burnBoardSN(snCode: Data) -> Promise<Void> {
        self.snCode = snCode
        var sn = snCode
        sn.insert(TestCommand.BoardWriteType.SNHeader.rawValue, at: 0)
        return (self.connector?.commandService?.write(data: sn, to: Characteristic.Command.Write.send))!
    }

    let defaultUserID: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF]

    // 单板：删除 userID
    func deleteBoardUserId() -> Promise<Void> {
        return (self.connector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.deleteUserID.rawValue]), to: Characteristic.Command.Write.send))!
    }

    // 单板：关机
    func shutdownBoard() -> Promise<Void> {
        return (self.connector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.shutDown.rawValue]), to: Characteristic.Command.Write.send))!
    }

    private var burnDeviceIDDispiseBag: Disposable?
    var appConfiguration: String?
    var sn: String?
    var userID: String?
    // 设置板子监听
    func burnDeviceNotify() {
        self.burnDeviceIDDispiseBag = self.connector?.commandService?.notify(characteristic: Characteristic.Command.Notify.receive)
            .subscribe (onNext: { [weak self] in
                guard let `self` = self else { return }
                print("tested_board - \(Date())-\($0)")
                if let type = TestCommand.FixtureToolAssert(rawValue: $0.first!) {
                    switch type {
                    case TestCommand.FixtureToolAssert.AppConfiguration:
                        var data = $0
                        data.removeFirst(1)
                        if contains(self.appConfigureData.copiedBytes, data) {
                            self.appConfiguration = String.init(data: self.appConfigureData, encoding: .utf8)
                            self.state.value = SystemTestState.burnAppConfigurationPass
                            print("--------app configuraiton success--------")
                        } else {
                            self.state.value = SystemTestState.TestFail
                        }
                        break
                    case TestCommand.FixtureToolAssert.SN:
                        var data = $0
                        data.removeFirst(1)
                        if contains(self.snCode.copiedBytes, data) {
                            self.sn = String.init(data: self.snCode, encoding: .utf8)
                            self.state.value = SystemTestState.burnSnCodePass
                            print("--------burn sn code success--------")
                        } else {
                            self.state.value = SystemTestState.TestFail
                        }
                        break
                    case TestCommand.FixtureToolAssert.UserID:
                        var data = $0
                        data.removeFirst(1)
                        if contains(self.defaultUserID, data) {
                            self.userID = String.init(data: Data(bytes: self.defaultUserID), encoding: .utf8)
                            self.state.value = SystemTestState.deleteUserIDPass
                            print("--------burn success--------")
                        } else {
                            self.state.value = SystemTestState.TestFail
                        }
                        break
                    default: break
                    }
                }
            })
    }

    private var contactDisposeBag: Disposable?
    private var eegDisposeBag: Disposable?

    var contactValue = Variable(-1)
    func contactNotify() {

        self.contactDisposeBag = self.connector?.eegService?.notify(characteristic: .contact)
            .subscribe(onNext: {
                self.contactValue.value = Int($0.first!)
                print("system ---- \($0.first!)")
                if $0.contains(0x00) {
                    self.state.value = SystemTestState.contactTestPass
                    self.contactDisposeBag?.dispose()
                } else {
                    self.state.value = SystemTestState.contactTestFail
                }
            }, onError: { error in
//                self.state.value = SystemTestState.TestFail
            })
        self.eegDisposeBag = self.connector?.eegService?.notify(characteristic: .data)
            .subscribe {}
    }

}
