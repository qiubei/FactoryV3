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
    private var testInfo: [String] = ["测试信息", "测试信息", "测试信息"]
    private var results: [String] {
        return [self.batteryInfo, self.contactInfo, self.burnDeviceIDInfo]
    }

    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var devicesTableview: UITableView!
    @IBOutlet weak var tableView: UITableView!
    @IBAction func restartAction(_ sender: UIButton) {
        self.manager.deleteBoardUserId().then { () -> () in
//            guard let `self` = self else { return }
            SVProgressHUD.showInfo(withStatus: "userID 删除成功")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.loadData()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        if self.navigationController?.viewControllers.count == 2 {
            self.manager.stopTest()
        }
    }

    private var hasAppConfigurationSuccessed = false
    // MARK: private
    private func stateNotify() {
        self.manager.state.asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: {
                let type = $0
                switch type {
                case .contactTestPass:
                    self.contactInfo = "通过"
                    break
                case .contactTestFail:
                    self.contactInfo = "失败"
                    break
                case .burnAppConfigurationPass:
                    self.hasAppConfigurationSuccessed = true
                    break
                case .burnAppConfigurationFail:
                    self.burnDeviceIDInfo = "失败"
                    self.testInfo[2] = "烧入 app 配置信息失败"
                    self.showResult(message: "测试不通过，请注意分类", false)
                    break
                case .burnSnCodePass:
                    if self.hasAppConfigurationSuccessed {
                        self.burnDeviceIDInfo = "通过"
                        self.testInfo[2] = self.manager.appConfiguration! + self.manager.sn!
                        self.resultLabel.isHidden = true
                        self.tableView.reloadData()
                    }
                    break
                case .burnSnCodeFail:
                    self.testInfo[2] = "烧入 sn 码失败"
                    self.burnDeviceIDInfo = "失败"
                    self.showResult(message: "测试不通过，请注意分类", false)
                    self.tableView.reloadData()
                case .deleteUserIDPass:
                    dispatch_to_main {
                        SVProgressHUD.showInfo(withStatus: "删除 User ID")
                        self.manager.shutdownBoard().then(execute: { () -> () in
                            SVProgressHUD.showInfo(withStatus: "关机成功")
                            self.manager.stopTest()
                            self.connectDiposeBag?.dispose()
                            self.connectDiposeBag = nil
                            self.navigationController?.popViewController(animated: true)
                        })
                    }
                    break
                case .TestFail:
                    self.showResult(message: "测试不通过，请注意分类", false)
                default: break
                }
                self.tableView.reloadData()
            }).disposed(by: self._disposeBag)
    }

    private func showResult(message: String,_ flag: Bool) {
        self.resultLabel.text = message
        self.resultLabel.isHidden = false
        if flag {
            self.resultLabel.textColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
            self.resultLabel.font = UIFont.systemFont(ofSize: 40)
        } else {
            self.resultLabel.adjustsFontSizeToFitWidth = true
            self.resultLabel.textColor = UIColor.red
        }
    }

    private func resetData() {
        self.batteryInfo = "未检测"
        self.contactInfo = "未检测"
        self.burnDeviceIDInfo = "未检测"
        self.tableView.reloadData()
    }

    private func loadData() {
        //TODO: ugly code
        self.resetData()
        self.manager.contactNotify()
        self.manager.burnDeviceNotify()
//        self.connectionNotify()
        self.contactValueChangeNotify()
        self.batteryInfoNotify()
        self.stateNotify()
        self.startSample().then { () -> () in
            print("----00000----")
        }
    }

    private var connectDiposeBag: Disposable?
    private var contactValueChangeDisposeBag: Disposable?
    private func contactValueChangeNotify() {
        self.contactValueChangeDisposeBag = self.manager.contactValue.asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: {
                self.testInfo[1] = String($0)
                if 0 == $0 {
                    self.contactValueChangeDisposeBag?.dispose()
                }
                self.tableView.reloadData()
            })
    }

    private func connectionNotify() {
        self.connectDiposeBag = self.manager.connector?.peripheral.rx_isConnected
            .subscribe(onNext: {
                if !$0 {
                    SVProgressHUD.showInfo(withStatus: "设备连接中断")
                    self.navigationController?.popViewController(animated: true)
                }
            })
    }

    private func batteryInfoNotify() {
        self.manager.connector?.batteryService?.read(characteristic: .battery).then { data in
                dispatch_to_main {
                    let battery = data.copiedBytes[0]
                    if battery >= 40 {
                        self.testInfo[0] = String(format: "%d%%", battery)
                        self.batteryInfo = "通过"
                    } else {
                        self.testInfo[0] = "当前电量低于 40%，不利于存储"
                        self.batteryInfo = "不合适"
                    }
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
            cell = UITableViewCell(style: .subtitle, reuseIdentifier: CELL_REUSE_ID)
        }
        cell.textLabel?.text = self.items[indexPath.row]
        cell.textLabel?.textColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
        cell.detailTextLabel?.text = self.testInfo[indexPath.row]

        let label = UILabel(frame: CGRect(x: 0, y: 0, width: 60, height: 44))
        label.text = self.results[indexPath.row]
        label.adjustsFontSizeToFitWidth = true
        switch self.results[indexPath.row] {
        case "通过":
            label.textColor = UIColor.green
            label.font = UIFont.systemFont(ofSize: 22)
        case "失败", "不合适":
            label.textColor = UIColor.red
            label.font = UIFont.systemFont(ofSize: 22)
        default:
            break
        }
        cell.accessoryView = label
        return cell
    }

    // tableview delegate method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if 2 == indexPath.row {
            self.performSegue(withIdentifier: "burnDeviceInfoID", sender: self)
        }
    }

    // 开始采集
    private func startSample() -> Promise<Void> {
        return (self.manager.connector?.commandService?.write(data: Data(bytes: [TestCommand.BoardWriteType.startSample.rawValue]), to: Characteristic.Command.Write.send))!
    }

    deinit {
        print("system test viewcontroller")
    }
}
