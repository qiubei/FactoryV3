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

    @IBOutlet weak var restartButton: UIButton!
    @IBOutlet weak var tableview: UITableView!
    @IBOutlet weak var resultsLabel: UILabel!
    @IBAction func restartTest(_ sender: UIButton) {
        SVProgressHUD.showInfo(withStatus: "重新测试")
        self.manager.stopTest()
        self.cleanUp()
        self.updateState()
    }

    var fixtureToolPeripheral: Peripheral!
    var manager: TestFlowManager!
    private let boradTestIterms = ["单板和工装连接测试","单板电池充电测试", "单板与 app 连接测试", "前段信号采集和分析测试", "单板脱落信号测试", "LED 灯（红绿蓝）测试", "按键反馈测试"]
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

    private func cleanUp() {
        testResults =  ["未测试","未测试", "未测试", "未测试", "未测试", "未测试", "未测试"]
        self.tableview.reloadData()
        self.manager.cleanUp()
        self.index = 0
//        self.resultsLabel.isHidden = true
        self.subscription?.dispose()
        self.subscription = nil
    }
    private func showResult(message: String) {
        self.resultsLabel.text = message
        self.resultsLabel.isHidden = false
    }

    private func updateState() {
        self.subscription = manager.state.asObservable().subscribe(onNext: { [weak self] in
            guard let `self` = self else { return }
            print($0)
            let type = $0
            switch type {
            case .ReadyTest:
                dispatch_to_main {
                    SVProgressHUD.showInfo(withStatus: "ReadyTest")
                }
                break
            case .StartTest:
                dispatch_to_main {
                    self.testResults[self.index] = "通过"
                    SVProgressHUD.showInfo(withStatus: "startTest")
                    self.tableview.reloadData()
                }
                break
            case .BoardChargePass:
                dispatch_to_main {
                    self.index += 1
                    self.testResults[self.index] = "通过"
                    SVProgressHUD.showInfo(withStatus: "BoardChargePass")
                    self.tableview.reloadData()
                }
                break
            case .BoardConnectedApp:
                dispatch_to_main {
                    self.index += 1
                    self.testResults[self.index] = "通过"
                    SVProgressHUD.showInfo(withStatus: "BoardConnectedApp")
                    self.tableview.reloadData()
                }
                break
            case .BrainAnalysePass:
                dispatch_to_main {
                    self.index += 1
                    self.testResults[self.index] = "通过"
                    SVProgressHUD.showInfo(withStatus: "BrainAnalysePass")
                    self.tableview.reloadData()
                }
                break
            case .EggContactCheckPass:
                dispatch_to_main {
                    self.index += 1
                    self.testResults[self.index] = "通过"
                    SVProgressHUD.showInfo(withStatus: "EggContactCheckPass")
                    self.tableview.reloadData()
                }
                break
            case .LEDShining:
                dispatch_to_main {
                    self.index += 1
                    self.testResults[self.index] = "通过"
                    SVProgressHUD.showInfo(withStatus: "LEDShining")
                    self.tableview.reloadData()
                }
                break
            case .LEDDeviceReply:
                dispatch_to_main {
                    self.index += 1
                    self.testResults[self.index] = "通过"
                    SVProgressHUD.showInfo(withStatus: "LEDDeviceReply")
                    self.showResult(message: "测试通过")
                    self.tableview.reloadData()
                }
                break
            case .Completed:
                dispatch_to_main {
                    SVProgressHUD.showInfo(withStatus: "测试通过")
                    self.resultsLabel.text = "测试通过"
                    self.tableview.reloadData()
                    self.subscription?.dispose()
                }
                break
            case .TestFail:
                dispatch_to_main { [weak self] in
                    guard let `self` = self else { return }
                    self.manager.stopTest()
                    if self.index < self.testResults.count - 1 {
                        self.index += 1
                    }
                    self.testResults[self.index] = "失败"
                    SVProgressHUD.showInfo(withStatus: "TestFail")
                    self.showResult(message: "\(self.boradTestIterms[self.index]) -- 测试不合格")
                    self.tableview.reloadData()
                    self.subscription?.dispose()
                }
                break
            case .BoardAborted:
                dispatch_to_main {
                    self.manager.stopTest()
                    if self.index < self.testResults.count - 1 {
                        self.index += 1
                    }
                    self.testResults[self.index] = "失败"
                    SVProgressHUD.showInfo(withStatus: "Aborted Complted")
                    self.tableview.reloadData()
                }
                break
            case .FixToolAborted:
                dispatch_to_main {
                    self.index += 1
                    self.testResults[self.index] = "失败"
                    self.navigationController?.popViewController(animated: true)
                    SVProgressHUD.showInfo(withStatus: "Aborted")
                    self.tableview.reloadData()
                }
                break
            default: break
            }
        })
    }
}
