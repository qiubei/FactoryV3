//
//  CommandManager.swift
//  V3
//
//  Created by Anonymous on 2018/2/2.
//  Copyright © 2018年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import Foundation
import RxSwift
import PromiseKit
import NaptimeBLE
import RxBluetoothKit

class CommandManager {
    static let shared = CommandManager()
    private var connector: Connector?
    private let scanner = Scanner()
    private init() {}

    func scan() -> Observable<ScannedPeripheral> {
        return self.scanner.scan()
    }

    func cancelScan() {
        self.scanner.stop()
    }

    func conntect(peripheral: Peripheral)-> Promise<Void> {
        self.connector = Connector(peripheral: peripheral)
        return self.connector!.tryConnect()
    }

    func disConnect() {
        if let connector = self.connector {
            connector.peripheral.cancelConnection().subscribe {
                print("disconnect success")
            }.dispose()
        }
    }

    func handshake()-> Promise<Void>? {
        return self.connector?.handshake()
    }

    func shutdown()-> Promise<Void>? {
        return self.connector?.commandService?.write(data: Data(bytes: [0x45]), to: .send)
    }

    func startSample()-> Promise<Void>? {
        return self.connector?.commandService?.write(data: Data(bytes: [0x01]), to: .send)
    }

    func stopSample()-> Promise<Void>? {
        return self.connector?.commandService?.write(data: Data(bytes:[0x02]), to: .send)
    }

    func startContact()-> Promise<Void>? {
        return self.connector?.commandService?.write(data: Data(bytes: [0x61]), to: .send)
    }

    func LED()-> Promise<Void>? {
        return self.connector?.commandService?.write(data: Data(bytes: [0x44]), to: .send)
    }

    func dUserId()-> Promise<Void>? {
        return self.connector?.commandService?.write(data: Data(bytes: [0x43]), to: .send)
    }

    func sn()-> Promise<Void>? {
        return self.connector?.commandService?.write(data: Data(bytes: [0x42]), to: .send)
    }

    func appConfiguration()-> Promise<Void>? {
        return self.connector?.commandService?.write(data: Data(bytes: [0x41]), to: .send)
    }

    func contactNotify()-> Observable<Bytes>? {
        return self.connector?.eegService?.notify(characteristic: .contact)
    }

    func eggNotify()-> Observable<Bytes>? {
        return self.connector?.eegService?.notify(characteristic: .data)
    }

    func dUserIDNotify()-> Observable<Bytes>? {
        return self.connector?.commandService?.notify(characteristic: .receive)
    }

    func pressNotify()-> Observable<Bytes>? {
        return self.connector?.commandService?.notify(characteristic: .receive)
    }

    func snNotify()-> Observable<Bytes>? {
        return self.connector?.commandService?.notify(characteristic: .receive)
    }

    func battery()-> Promise<Data>? {
        return self.connector?.batteryService?.read(characteristic: .battery)
    }

    func manufacturer()-> Promise<Data>? {
        return self.connector?.deviceInfoService?.read(characteristic: .manufacturer)
    }

    func macAddress()-> Promise<Data>? {
        return self.connector?.deviceInfoService?.read(characteristic: .mac)
    }

    func serial()-> Promise<Data>? {
        return self.connector?.deviceInfoService?.read(characteristic: .serial)
    }

    func hardwareVersion()-> Promise<Data>? {
        return self.connector?.deviceInfoService?.read(characteristic: .hardwareRevision)
    }

    func firmwareVersion()-> Promise<Data>? {
        return self.connector?.deviceInfoService?.read(characteristic: .firmwareRevision)
    }

    func dfu()-> Promise<Void>? {
        return self.connector?.commandService?.write(data: Data(bytes: [0x44]), to: .send)
    }
    
    func intoTestMode()-> Promise<Void>? {
        return self.connector?.commandService?.write(data: Data(bytes: [0x48]), to: .send)
    }
}
