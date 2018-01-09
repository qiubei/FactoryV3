//
//  Connector.swift
//  NaptimeBLE
//
//  Created by HyanCat on 03/11/2017.
//  Copyright © 2017 EnterTech. All rights reserved.
//

import Foundation
import CoreBluetooth
import RxBluetoothKit
import RxSwift
import PromiseKit

public protocol DisposeHolder {
    var disposeBag: DisposeBag { get }
}

extension RxBluetoothKit.Service: Hashable {
    public var hashValue: Int {
        return self.uuid.hash
    }
}

public final class Connector: DisposeHolder {

    public typealias ConnectResultBlock = ((Bool) -> Void)
    public let peripheral: Peripheral

    public private(set) var connectService: ConnectService?
    public private(set) var commandService: CommandService?
    public private(set) var eegService: EEGService?
    public private(set) var batteryService:  BatteryService?
    public private(set) var dfuService: DFUService?
    public private(set) var deviceInfoService: DeviceInfoService?

    public var allServices: [BLEService] {
        return ([connectService, commandService, eegService, batteryService, dfuService, deviceInfoService] as [BLEService?]).filter { $0 != nil } as! [BLEService]
    }

    private(set) var mac: Data?

    private (set) public var disposeBag: DisposeBag = DisposeBag()
    private var _disposable: Disposable?

    public init(peripheral: Peripheral) {
        self.peripheral = peripheral
    }

    public func tryConnect() -> Promise<Void> {
        let promise = Promise<Void> { (fulfill, reject) in
            _disposable = peripheral.connect()
                .flatMap {
                    $0.discoverServices(nil)
                }.flatMap {
                    Observable.from($0)
                }.`do`(onNext: { [weak self] in
                    print("uuid: \($0.uuid.uuidString)")
                    guard let `self` = self else { return }
                    guard let `type` = NaptimeBLE.ServiceType(rawValue: $0.uuid.uuidString) else { return }
                    switch `type` {
                    case .connect:
                        self.connectService = ConnectService(rxService: $0)
                    case .command:
                        self.commandService = CommandService(rxService: $0)
                    case .battery:
                        self.batteryService = BatteryService(rxService: $0)
                    case .eeg:
                        self.eegService = EEGService(rxService: $0)
                    case .dfu:
                        self.dfuService = DFUService(rxService: $0)
                    case .deviceInfo:
                        self.deviceInfoService = DeviceInfoService(rxService: $0)
                    }
                }).flatMap {
                    $0.discoverCharacteristics(nil)
                }.flatMap {
                    Observable.from($0)
                }.subscribe(onNext: { _ in
                    //
                }, onError: { error in
                    print("\(error)")
                    reject(error)
                }, onCompleted: {
//                    guard self.commandService != nil && self.batteryService != nil && self.eegService != nil && self.dfuService != nil && self.deviceInfoService != nil else {
//                        reject(BLEError.connectFail)
//                        return
//                    }
                    fulfill(())
                })
        }
        return promise
    }

    public func cancel() {
        _disposable?.dispose()
    }

    private var _stateListener: Disposable?
    private var _handshakeListener: Disposable?

    public func handshake() -> Promise<Void> {

        let promise = Promise<Void> { (fulfill, reject) in

            let disposeListener = { [weak self] in
                self?._stateListener?.dispose()
                self?._handshakeListener?.dispose()
            }
            // 监听状态
            _stateListener = self.connectService!.notify(characteristic: .state).subscribe(onNext: { bytes in
                print("state: \(bytes)")
                guard let state = HandshakeState(rawValue: bytes) else { return }

                switch state {
                case .success:
                    fulfill(())
                case .error(let err):
                    reject(err)
                }
                disposeListener()
            }, onError: { error in
                print("state error: \(error)")
                reject(error)
                disposeListener()
            })
            _stateListener?.disposed(by: disposeBag)

            Thread.sleep(forTimeInterval: 0.1)
            // 监听 第二步握手
            _handshakeListener = self.connectService!.notify(characteristic: .handshake).subscribe(onNext: { data in
                print("握手返回: \(data)")
                // 发送 第三步握手
                self.connectService?.write(data: Data(bytes: [0x03, 0x00, 0x00, 0x00, 0x00]), to: .handshake)
                    .catch { error in
                    reject(error)
                }
            }, onError: { error in
                print("握手 error: \(error)")
                reject(error)
                disposeListener()
            })
            _handshakeListener?.disposed(by: disposeBag)

            // 开始握手
            Thread.sleep(forTimeInterval: 0.1)
            // 读取 mac 地址
            self.deviceInfoService!.read(characteristic: .mac)
                .then { data -> Promise<Void> in
                    self.mac = data
                    print("mac: \(data)")
                    // 发送 user id
                    return self.connectService!.write(data: Data(bytes: [0x00,0x12,0x34,0x56,0x78]), to: .userID)
                }
                .then {
                    // 发送 第一步握手
                    return self.connectService!.write(data: Data(bytes: [0x01, 0x00, 0x00, 0x00, 0x00]), to: .handshake)
                }.catch { error in
                    print("握手 error: \(error)")
            }
        }

        return promise
    }
}
