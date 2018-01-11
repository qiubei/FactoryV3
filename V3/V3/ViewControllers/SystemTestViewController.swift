//
//  SystemTestViewController.swift
//  V3
//
//  Created by Anonymous on 2018/1/1.
//  Copyright © 2018年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift
import NaptimeBLE
import SVProgressHUD
import PromiseKit

class SystemTestViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    var peripheral: Peripheral!
    private let manager = SystemTestManager.shared
    private let _disposeBag = DisposeBag()
    private let items = ["电池信息", "脱落检测", "烧入 device ID"]
    private var batteryInfo = "未检测"
    private var contactInfo = "未检测"
    private var burnDeviceIDInfo = "未检测"
    private var results: [String] {
        return [self.batteryInfo, self.contactInfo, self.burnDeviceIDInfo]
    }

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var devicesTableview: UITableView!
    @IBOutlet weak var tableView: UITableView!
    @IBAction func restartAction(_ sender: UIButton) {
        self.manager.deleteBoardUserId().then { [weak self]() -> () in
            guard let `self` = self else { return }
            SVProgressHUD.showInfo(withStatus: "userID 删除成功")
            self.manager.shutdownBoard().then(execute: { () -> () in
                dispatch_to_main {
                    SVProgressHUD.showInfo(withStatus: "关机成功")
                    self.manager.stopTest()
                    self.navigationController?.popViewController(animated: true)
                }
            })
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.loadData()
    }

    private var hasAppConfigurationSuccessed = false
    // MARK: private
    private func stateNotify() {
        self.manager.state.asObservable()
            .subscribe(onNext: {
                let type = $0
                switch type {
                case .contactTestPass:
                    dispatch_to_main {
                        self.contactInfo = "通过"
                        self.tableView.reloadData()
                    }
                    break
                case .burnAppConfigurationPass:
                    self.hasAppConfigurationSuccessed = true
                    break
                case .burnSnCodePass:
                    if self.hasAppConfigurationSuccessed {
                        dispatch_to_main {
                            self.burnDeviceIDInfo = "通过"
                            self.tableView.reloadData()
                        }
                    }
                    break
                case .deleteUserIDPass:
                    dispatch_to_main {
                        SVProgressHUD.showInfo(withStatus: "删除 User ID")
                    }
                    break
                default: break
                }
            }).disposed(by: self._disposeBag)
    }

    private func resetData() {
        self.batteryInfo = "未检测"
        self.contactInfo = "未检测"
        self.burnDeviceIDInfo = "未检测"
        self.tableView.reloadData()
    }

    private func loadData() {
        self.manager.contactNotify()
        self.manager.burnDeviceNotify()
        self.connectionNotify()
        self.batteryInfoNotify()
        self.stateNotify()
        self.startSample().then { () -> () in
            print("----00000----")
        }
    }


    private var eegNotifyDisposeBag: Disposable?

    private func connectionNotify() {
        self.manager.connector?.peripheral.rx_isConnected
            .subscribe(onNext: {
                if !$0 {
                    SVProgressHUD.showInfo(withStatus: "设备连接中断")
                    self.navigationController?.popViewController(animated: true)
                }
            }).disposed(by: self._disposeBag)
    }

    private func batteryInfoNotify() {
        self.manager.connector?.batteryService?.read(characteristic: .battery).then { data in
                dispatch_to_main {
                    self.batteryInfo = String(format: "%d%%", data.copiedBytes[0])
                    self.tableView.reloadData()
                }
            }.catch { _ in
                self.batteryInfo = "失败"
                SVProgressHUD.showInfo(withStatus: "电池测试失败")
        }
    }

    // tableview datesource method
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let CELL_REUSE_ID = "CELL_REUSE_ID"
        let cell: UITableViewCell
        if let reuseCell = tableView.dequeueReusableCell(withIdentifier: CELL_REUSE_ID) {
            cell = reuseCell
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: CELL_REUSE_ID)
        }
        cell.textLabel?.text = self.items[indexPath.row]
        cell.textLabel?.textColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
        cell.detailTextLabel?.text = self.results[indexPath.row]

        switch self.results[indexPath.row] {
        case "通过":
            cell.detailTextLabel?.textColor = UIColor.green
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 22)
        case "失败":
            cell.detailTextLabel?.textColor = UIColor.red
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 16)
        default:
            break
        }
        return cell
    }

    // tableview delegate method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if 2 == indexPath.row {
            self.performSegue(withIdentifier: "burnDeviceInfoID", sender: self)
            self.stopSmaple().then(execute: { () -> () in
            })
        }
    }

    // 开始采集
    private func startSample() -> Promise<Void> {
        return (self.manager.connector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.startSample.rawValue]), to: Characteristic.Command.Write.send))!
    }

    // 停止采集
    private func stopSmaple() -> Promise<Void> {
        return (self.manager.connector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.stopSample.rawValue]), to: Characteristic.Command.Write.send))!
    }

    deinit {
        print("system test viewcontroller")
    }
}
