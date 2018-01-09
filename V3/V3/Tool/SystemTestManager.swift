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

class SystemTestManager {
    static let shared = SystemTestManager()
//    var hasBurnDeviceIDSuccessed = Variable(false)
    var connector: Connector?

    private var scanner = NaptimeBLE.Scanner()
    private let _disposeBag = DisposeBag()
    private init() {}

    // 搜索设备
    func scan() -> Observable<ScannedPeripheral> {
        return scanner.scan()
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
//        self.cleanUp()
    }

    private func cleanUp() {
//        self.hasBurnDeviceIDSuccessed = Variable(false)
//        self.hasAppConfigureDataTestPass = false
//        self.hasSNCodeTestPass = false
//        self.hasDeleteUesrIDTestPass = false
        self.connector = nil
        self.snCode = Data()
        self.appConfigureData = Data()
    }

    // 连接蓝牙设备
    func startTestWith(peripheral: Peripheral) -> Promise<Void>{
        self.connector = Connector(peripheral: peripheral)
        return self.connector!.tryConnect()
    }

    var appConfigureData = Data()

    // 单板：烧入 app 配置项
    func burnBoardAppConfigure(appConfigureData: Data) -> Promise<Void> {
        self.appConfigureData = appConfigureData
        var appConfigure = appConfigureData
        appConfigure.insert(TestCommand.BoardWriteType.AppConfigurationHeader.rawValue, at: 0)
        return (self.connector?.commandService?.write(data: appConfigure, to: Characteristic.Command.Write.send))!
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
}
