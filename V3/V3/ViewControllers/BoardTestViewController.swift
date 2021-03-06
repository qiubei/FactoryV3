//
//  TesttingViewController.swift
//  V3
//
//  Created by Anonymous on 2017/12/26.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import RxSwift
import SVProgressHUD
import RxBluetoothKit

class BoardTestViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var resultsLabel: UILabel!

    var fixtureToolPeripheral: Peripheral!
    var manager: BoardTestManager!
    private let boradTestIterms = ["单板和工装连接测试","单板电池充电测试", "单板与 app 连接测试", "前段信号采集和分析测试", "单板脱落信号测试", "右腿信号测试", "LED 灯（红绿蓝）测试"]
    private var testResults =  ["未测试","未测试", "未测试", "未测试", "未测试", "未测试", "未测试"]
    private let _disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableview.dataSource = self
        self.tableview.delegate = self
        self.updateState()
        dispatch_after(1){
            self.manager.connectWith(peripheral: self.fixtureToolPeripheral)
        }
        self.resultsLabel.isHidden = true
        let index =  self.navigationController!.viewControllers.index(of: self)! - 1
        self.navigationController?.viewControllers.remove(at: index)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        if 1 == self.navigationController?.viewControllers.count {
            self.manager.stopScan()
            self.manager.cancelConnection()
        }
    }

    // tableview datasource method
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.boradTestIterms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifierID = "CELL_IDENTIFIER_ID"
        let cell: UITableViewCell
        if let reusedCell = tableView.dequeueReusableCell(withIdentifier: identifierID) {
            cell = reusedCell
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: identifierID)
        }
        cell.textLabel?.text = self.boradTestIterms[indexPath.row]
        cell.textLabel?.textColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
        cell.detailTextLabel?.text = self.testResults[indexPath.row]
        switch self.testResults[indexPath.row] {
        case "完成":
            cell.detailTextLabel?.textColor = UIColor.blue
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 16)
        case "通过":
            cell.detailTextLabel?.textColor = UIColor.green
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 22)
        case "失败":
            cell.detailTextLabel?.textColor = UIColor.red
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 22)
        default:
            cell.detailTextLabel?.textColor = UIColor.lightGray
            cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 16)
        }
        return cell
    }

    // tableview delegate method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1.0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }

    // MARK: private
    private var index = 0
    private var subscription: Disposable?
    typealias EmptyBlock = () -> ()

    private var alertViewController: UIAlertController?
    private func addAlertSheet(title: String) {
        if nil == self.alertViewController  {
            self.alertViewController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "通过", style: .default) { (alert) in
                self.testResults[self.index] = "通过"
                self.manager.state.value = TestFlowState.Completed
                Logger.shared.log(message: "单板测试通过", lavel: .Show)
            }
            let cancelAction = UIAlertAction(title: "失败", style: .cancel) { (alert) in
                self.manager.state.value = TestFlowState.TestFail
                Logger.shared.log(message: "LED 灯测试失败", lavel: .Error)
            }
            self.alertViewController!.addAction(okAction)
            self.alertViewController!.addAction(cancelAction)
        }
        self.present(self.alertViewController!, animated: true, completion: nil)
    }

    private func cleanUp() {
        testResults =  ["未测试","未测试", "未测试", "未测试", "未测试", "未测试", "未测试"]
        self.index = 0
        self.resultsLabel.isHidden = true
        self.tableview.reloadData()
    }

    private func showResult(message: String,_ flag: Bool) {
        self.resultsLabel.text = message
        self.resultsLabel.isHidden = false
        if flag {
            self.resultsLabel.textColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
            self.resultsLabel.font = UIFont.systemFont(ofSize: 40)
        } else {
            self.resultsLabel.adjustsFontSizeToFitWidth = true
            self.resultsLabel.textColor = UIColor.red
        }
    }

    private func updateState() {
        self.subscription = self.manager.state.asObservable()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: {
            let type = $0
                switch type {
                case .ReadyTest:
                    self.index = 0
                    // 清空 Log 信息
                    let firstLog = Logger.shared.logArray?.first
                    Logger.shared.cleanUp()
                    Logger.shared.logArray?.append(firstLog!)
                case .StartTest, .BoardChargePass, .BoardConnectedApp, .BrainAnalysePass, .BoardRightVoltagePass, .EggContactCheckPass:
                    self.testResults[self.index] = "通过"
                    print("\(type) ---- \(self.testResults[self.index])")
                    if self.index < self.testResults.count-1 {
                        self.index += 1
                    }
                case .LEDDeviceReply:
                    self.addAlertSheet(title: self.boradTestIterms[self.index])
                case .TestFail:
                    self.testResults[self.index] = "失败"
                    self.showResult(message: self.boradTestIterms[self.index] + "不合格", false)
                case .BoardDisConnectFixtool:
                    self.alertViewController?.dismiss(animated: true, completion: nil)
                    self.cleanUp()
                case .Completed:
                    self.showResult(message: "测试通过", true)
                case .FixToolAborted:
                    self.navigationController?.popViewController(animated: true)
                default: break
                }
                self.tableview.reloadData()
        })
    }
}
