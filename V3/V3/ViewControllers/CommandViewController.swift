//
//  CommandViewController.swift
//  V3
//
//  Created by Anonymous on 2018/2/2.
//  Copyright © 2018年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import RxBluetoothKit
import SVProgressHUD
import RxSwift
import UIActionKit

class CommandViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    private let command = CommandManager.shared
    private var selectedPeripheral: ScannedPeripheral?
    @IBOutlet weak var tableView: UITableView!

    @IBOutlet weak var scanButton: UIButton!

    private var isDeviceConnected = false
//    private let disposeBag = DisposeBag()

    @IBAction func commandAction(_ sender: UIButton) {
        switch sender.tag % 900 {
        case 1:
            if !isDeviceConnected {
                self.isDeviceConnected = true
                sender.setTitle("断开", for: .normal)
                if let peripheral = self.selectedPeripheral {
                    self.command.conntect(peripheral: peripheral.peripheral).then(execute: { () -> () in
                        SVProgressHUD.showSuccess(withStatus: "已经连")
                    }).catch(execute: { (error) in
                        SVProgressHUD.showInfo(withStatus: "连接失败")
                    })
                } else {
                    SVProgressHUD.showInfo(withStatus: "请选择要连接的设备")
                }
            } else {
                self.isDeviceConnected = false
                sender.setTitle("连接", for: .normal)
                self.command.disConnect()
                self.selectedPeripheral = nil
                
            }
            break
        case 2:
            self.command.handshake()?.then(execute: { () -> () in
                SVProgressHUD.showSuccess(withStatus: "握手成功")
            }).catch(execute: { (error) in
                    SVProgressHUD.dismiss()
                    SVProgressHUD.showError(withStatus: "握手失败")
            })
            break
        case 3:
            self.command.shutdown()?.then(execute: { () -> () in
                SVProgressHUD.showSuccess(withStatus: "关机成功")
            }).catch(execute: { (error) in
                SVProgressHUD.showInfo(withStatus: "关机失败")
            })
            break
        case 4:
            self.command.startSample()?.then(execute: { () -> () in
                SVProgressHUD.showSuccess(withStatus: "开始采集")
            }).catch(execute: { (error) in
                SVProgressHUD.showError(withStatus: "发送指令失败")
            })
            break
        case 5:
            self.command.stopSample()?.then(execute: { () -> () in
                SVProgressHUD.showSuccess(withStatus: "停止采集")
            }).catch(execute: { (error) in
                SVProgressHUD.showError(withStatus: "发送指令失败")
            })
            break
        case 6:
            self.command.startContact()?.then(execute: { () -> () in
                SVProgressHUD.showSuccess(withStatus: "开始脱落检测")
            }).catch(execute: { (error)  in
                SVProgressHUD.showError(withStatus: "发送指令失败")
            })
            break
        case 7:
            self.command.LED()?.then(execute: { () -> () in
                SVProgressHUD.showSuccess(withStatus: "LED 灯闪烁")
            }).catch(execute: { (error)  in
                SVProgressHUD.showError(withStatus: "发送指令失败")
            })
            break
        case 8:
            self.command.dUserId()?.then(execute: { () -> () in
                SVProgressHUD.showSuccess(withStatus: "删除 User ID")
            }).catch(execute: { (error)  in
                SVProgressHUD.showError(withStatus: "发送指令失败")
            })
            break
        case 9:
            self.command.startContact()?.then(execute: { () -> () in
                SVProgressHUD.showSuccess(withStatus: "sn 码烧入")
            }).catch(execute: { (error)  in
                SVProgressHUD.showError(withStatus: "发送指令失败")
            })
            break
        case 10:
            self.command.startContact()?.then(execute: { () -> () in
                SVProgressHUD.showSuccess(withStatus: "烧入配置信息")
            }).catch(execute: { (error)  in
                SVProgressHUD.showError(withStatus: "发送指令失败")
            })
            break
        case 11:
            if let observable = self.command.contactNotify() {
                observable.observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: {
                    SVProgressHUD.showInfo(withStatus: "\($0)")
                }).disposed(by: self.disposeBag)
            } else {
                SVProgressHUD.showError(withStatus: "清先连接设备")
            }
            break
        case 12:
            if let observable = self.command.eggNotify() {
                observable.observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: {
                        SVProgressHUD.showInfo(withStatus: "\($0)")
                    }).disposed(by: self.disposeBag)
            } else {
                SVProgressHUD.showError(withStatus: "清先连接设备")
            }
            break
        case 13:
            if let observable = self.command.dUserIDNotify() {
                observable.observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: {
                        SVProgressHUD.showInfo(withStatus: "\($0)")
                    }).disposed(by: self.disposeBag)
            } else {
                SVProgressHUD.showError(withStatus: "清先连接设备")
            }
            break
        case 14:
            if let observable = self.command.pressNotify() {
                observable.observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: {
                        SVProgressHUD.showInfo(withStatus: "\($0)")
                    }).disposed(by: self.disposeBag)
            } else {
                SVProgressHUD.showError(withStatus: "清先连接设备")
            }
            break
        case 15:
            if let observable = self.command.snNotify() {
                observable.observeOn(MainScheduler.asyncInstance)
                    .subscribe(onNext: {
                        SVProgressHUD.showInfo(withStatus: "\($0)")
                    }).disposed(by: self.disposeBag)
            } else {
                SVProgressHUD.showError(withStatus: "请先连接设备")
            }
            break
        case 16:
            if let promise = self.command.battery() {
                promise.then(execute: { (data) -> () in
                    SVProgressHUD.showInfo(withStatus: "电池 \(data.copiedBytes.first!)")
                }).catch(execute: { (error) in
                    SVProgressHUD.showError(withStatus: "获取电池失败")
                })
            } else {
                SVProgressHUD.showError(withStatus: "请连接设备")
            }
            break
        case 17:
            if let promise = self.command.manufacturer() {
                promise.then(execute: { (data) -> () in
                    SVProgressHUD.showSuccess(withStatus: "\(data)")
                }).catch(execute: { (error) in
                    SVProgressHUD.showError(withStatus: "获取制造产商信息失败")
                })
            } else {
                SVProgressHUD.showError(withStatus: "请连接设备")
            }
            break
        case 18:
            if let promise = self.command.macAddress() {
                promise.then(execute: { (data) -> () in
                    SVProgressHUD.showSuccess(withStatus: "\(data)")
                }).catch(execute: { (error) in
                    SVProgressHUD.showError(withStatus: "获取 mac 信息失败")
                })
            } else {
                SVProgressHUD.showError(withStatus: "请连接设备")
            }
            break
        case 19:
            if let promise = self.command.serial() {
                promise.then(execute: { (data) -> () in
                    SVProgressHUD.showSuccess(withStatus: "\(data)")
                }).catch(execute: { (error) in
                    SVProgressHUD.showError(withStatus: "获取序列号失败")
                })
            } else {
                SVProgressHUD.showError(withStatus: "请连接设备")
            }
            break
        case 20:
            if let promise = self.command.hardwareVersion() {
                promise.then(execute: { (data) -> () in
                    SVProgressHUD.showSuccess(withStatus: "\(data)")
                }).catch(execute: { (error) in
                    SVProgressHUD.showError(withStatus: "获取硬件版本失败")
                })
            } else {
                SVProgressHUD.showError(withStatus: "请连接设备")
            }
            break
        case 21:
            if let promise = self.command.firmwareVersion() {
                promise.then(execute: { (data) -> () in
                    SVProgressHUD.showSuccess(withStatus: "\(data)")
                }).catch(execute: { (error) in
                    SVProgressHUD.showError(withStatus: "获取固件版本失败")
                })
            } else {
                SVProgressHUD.showError(withStatus: "请连接设备")
            }
            break
        case 22:
            break
        case 23:
            if let promise = self.command.intoTestMode() {
                promise.then(execute: { () -> () in
                    SVProgressHUD.showInfo(withStatus: "进入测试模式")
                }).catch(execute: { (error) in
                    SVProgressHUD.showError(withStatus: "发送指令失败")
                })
            } else {
                SVProgressHUD.showError(withStatus: "请先连接设备")
            }
            break
        case 24:
            break
        case 25:
            break
        default:
            break
        }
    }

    private var isScanning = false
    private var disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.scanButton.action = Action(name: "scanBtn")
        self.tableView.dataSource = self
        self.tableView.delegate = self

        SVProgressHUD.setMaximumDismissTimeInterval(0.5) 
        SVProgressHUD.setMinimumDismissTimeInterval(0.5)
    }

    @objc(handleScanBtn:)
    private func handle(act: Action) -> Result? {
        if !self.isScanning {
            self.isScanning = true
            self.scanButton.setTitle("停止", for: .normal)
            self.command.scan().observeOn(MainScheduler.asyncInstance)
                .subscribe(onNext: {
                    self.scanedPeripherals.append($0)
                    print($0.peripheral.name)
                    self.tableView.reloadData()
                }).disposed(by: self.disposeBag)
        } else {
            self.scanButton.setTitle("扫描", for: .normal)
            self.isScanning = false
            self.command.cancelScan()
            self.scanedPeripherals.removeAll()
            
        }
        return nil
    }

    private var scanedPeripherals = [ScannedPeripheral]()

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.scanedPeripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell_identifier = "cell_identifier"
        let cell: UITableViewCell
        if let reusedCell = tableView.dequeueReusableCell(withIdentifier: cell_identifier) {
            cell = reusedCell
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: cell_identifier)
        }

        cell.textLabel?.text = self.scanedPeripherals[indexPath.row].peripheral.name
        if let peripheral = self.selectedPeripheral, peripheral === self.scanedPeripherals[indexPath.row] {
            cell.detailTextLabel?.text = "已选中"
        } else {
            cell.detailTextLabel?.text = self.scanedPeripherals[indexPath.row].rssi.stringValue
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.selectedPeripheral = self.scanedPeripherals[indexPath.row]
        self.tableView.reloadData()
    }
}
