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
    private var isCompleted = false
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

    private var hasAppConfigureDataTestPass = false
    private var hasSNCodeTestPass = false
    private var hasDeleteUesrIDTestPass = false

    private func resetData() {
        self.batteryInfo = "未检测"
        self.contactInfo = "未检测"
        self.burnDeviceIDInfo = "未检测"
        self.tableView.reloadData()
    }

    private func loadData() {
        Timer.after(1) {
            self.burnDeviceNotify()
            self.connectionNotify()
            self.batteryInfoNotify()
            self.contactInfoNotify()
        }
    }
    // 设置板子监听
    func burnDeviceNotify() {
        self.manager.connector?.commandService?.notify(characteristic: Characteristic.Command.Notify.receive)
            .subscribe (onNext: { [weak self] in
                guard let `self` = self else { return }
                print("tested_board - \(Date())-\($0)")
                if let type = TestCommand.FixtureToolAssert(rawValue: $0.first!) {
                    switch type {
                    case TestCommand.FixtureToolAssert.AppConfiguration:
                        var data = $0
                        data.removeFirst(1)
                        if V3.contains(self.manager.appConfigureData.copiedBytes, data) {
                            self.hasAppConfigureDataTestPass = true
                            if self.hasSNCodeTestPass {
                                self.burnDeviceIDInfo = "通过"
                            }
                            print("--------app configuraiton success--------")
                        }
                        break
                    case TestCommand.FixtureToolAssert.SN:
                        var data = $0
                        data.removeFirst(1)
                        if V3.contains(self.manager.snCode.copiedBytes, data) {
                            self.hasSNCodeTestPass = true
                            if self.hasAppConfigureDataTestPass {
                                self.burnDeviceIDInfo = "通过"
                            }
                            print("--------burn sn code success--------")
                        }
                        break
                    case TestCommand.FixtureToolAssert.UserID:
                        var data = $0
                        data.removeFirst(1)
                        if V3.contains(self.manager.defaultUserID, data) && self.hasAppConfigureDataTestPass && self.hasSNCodeTestPass {
                            self.hasDeleteUesrIDTestPass = true
                            print("--------burn success--------")
                        }
                        break
                    default: break
                    }
                }
            }).disposed(by: self._disposeBag)
    }

    private func connectionNotify() {
        self.manager.connector?.peripheral.rx_isConnected
            .subscribe(onNext: {
                if !$0 {
                    SVProgressHUD.showInfo(withStatus: "失败")
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

    private func contactInfoNotify() {
        self.manager.connector?.eegService?.notify(characteristic: .contact).subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            if let _ = $0.first(where: {$0.hashValue == 0}) {
                self.contactInfo = "通过"
                self.tableView.reloadData()
            }
        }).disposed(by: self._disposeBag)
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
        }
    }
}
