//
//  BurnDeviceIDViewController.swift
//  V3
//
//  Created by Anonymous on 2017/12/28.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import SwiftyUserDefaults
import NaptimeBLE
import SVProgressHUD
import SwiftyTimer
import RxSwift

class BurnDeviceIDViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var burnIDButton: UIButton!

    @IBAction func burnDeviceIDAction(_ sender: UIButton) {
        self.burnAppConfigurationCode()
        Timer.after(2) {
            self.burnSNCode()
        }
    }

    private var hasBurnAppConfiguraitonSuccessed = false
    // 烧入配置信息
    private func burnAppConfigurationCode() {
        if let data = self.appConfigurationData {
            print(data)
            SystemTestManager.shared.burnBoardAppConfigure(appConfigureData: data).then { () -> () in
                dispatch_to_main {
                    self.hasBurnAppConfiguraitonSuccessed = true
                    SVProgressHUD.showInfo(withStatus: "配置信息烧入成功")
                }
                }.catch(execute: { (error) in
                    self.manager.state.value = SystemTestState.TestFail
                })
        } else {
            dispatch_to_main {
                SVProgressHUD.showInfo(withStatus: "烧入 App 配置失败")
                self.manager.state.value = SystemTestState.burnAppConfigurationFail
            }
        }
    }

    // 烧入 sn 码
    private func burnSNCode() {
        if let text = textField.text {
            if text.starts(with: "NP2") && text.count == 16 {
                SystemTestManager.shared.burnBoardSN(snCode: text.data(using: .utf8)!).then { () -> () in
                    dispatch_to_main {
                        if self.hasBurnAppConfiguraitonSuccessed {
                            SVProgressHUD.showInfo(withStatus: "Device ID 烧入成功")
                            dispatch_after(1) {
                                self.navigationController?.popViewController(animated: true)
                            }
                        }
                    }
                }
            } else {
                dispatch_to_main {
                    SVProgressHUD.showInfo(withStatus: "烧入 Device ID 失败")
                    self.manager.state.value = SystemTestState.burnSnCodeFail
                }
            }
        }
    }

    private let manager = SystemTestManager.shared
    var conntector: Connector!

    var appConfigurationData: Data? {
        return (self.hardwareVersion + self.distributor + self.customMade + self.production + self.productedDate).data(using: .utf8)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.inputSNCode()
        self.loadUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        self.tableView.reloadData()
    }

    private let _disposeBag = DisposeBag()

    private func loadUI() {
        self.burnIDButton.isEnabled = true
        self.burnIDButton.backgroundColor = UIColor.lightGray
    }

    private func inputSNCode() {
        self.textField.clearButtonMode = .whileEditing
        self.textField.keyboardType = .asciiCapable
        self.textField.layer.borderColor = UIColor.red.cgColor
        self.textField.becomeFirstResponder()
        self.textField.addTarget(self, action: #selector(self.snCodeValueChange(textField:)), for: .valueChanged)
        self.textField.addTarget(self, action: #selector(self.snCodeValueChange(textField:)), for: .editingChanged)
    }

    @objc private func snCodeValueChange(textField: UITextField) {
        guard let text = textField.text else { return }
        if text.starts(with: "NP") {
            Defaults[.snCode] = text
            if text.count > 0 {
                self.burnIDButton.isEnabled = true
                self.burnIDButton.backgroundColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
            } else {
                self.burnIDButton.isEnabled = false
                self.burnIDButton.backgroundColor = UIColor.lightGray
            }
        } else {
            SVProgressHUD.showInfo(withStatus: "SN 码必须以 NP 开头")
        }
    }

    private let configurationTitleItems = ["硬件版本", "渠道", "定制", "生产商", "生产日期"]

    // 需要做持久化
    private var hardwareVersion: String {
        return DeviceInfo.shared.hardwareVersion
    }
    private var distributor: String {
        return DeviceInfo.shared.distributor
    }
    private var customMade: String {
        return DeviceInfo.shared.customMade
    }
    private var production: String {
        return DeviceInfo.shared.production
    }
    private var productedDate: String {
        return  DeviceInfo.shared.productdDate
    }

    private var configurationDataIterms: [String] {
        get {
            return [self.hardwareVersion, self.distributor, self.customMade, self.production, self.productedDate]
        }

        set {
            DeviceInfo.shared.hardwareVersion = newValue[0]
            DeviceInfo.shared.distributor = newValue[1]
            DeviceInfo.shared.customMade = newValue[2]
            DeviceInfo.shared.production = newValue[3]
            DeviceInfo.shared.productdDate = newValue[4]
        }
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.configurationDataIterms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifierID = "STATIC_STRING_ID"
        let cell: UITableViewCell
        if let reusedCell = tableView.dequeueReusableCell(withIdentifier: identifierID) {
            cell = reusedCell
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: identifierID)
        }
        cell.textLabel?.text = self.configurationTitleItems[indexPath.row]
        cell.textLabel?.textColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
        cell.detailTextLabel?.text = self.configurationDataIterms[indexPath.row]
        return cell
    }

    // tableview delegate method
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
