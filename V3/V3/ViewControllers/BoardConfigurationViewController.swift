//
//  BoardConfigurationViewController.swift
//  V3
//
//  Created by Anonymous on 2017/12/26.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import SwiftyUserDefaults

typealias TextFieldBlock = (_ textField: UITextField) -> Void

class BoardConfigurationViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

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
            return [DeviceInfo.shared.hardwareVersion,
                    DeviceInfo.shared.distributor,
                    DeviceInfo.shared.customMade,
                    DeviceInfo.shared.production,
                    DeviceInfo.shared.productdDate]
        }
    }

    @IBOutlet weak var tableview: UITableView!

    private var picker: PickerView?

    @objc
    private func addValueChangeObserver(notification: Notification) {
        self.tableview.reloadData()
    }

    private func addObserves() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.addValueChangeObserver(notification:)),
                                               name: DefaultsKeys.hardwareVersion.notificationName,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.addValueChangeObserver(notification:)),
                                               name: DefaultsKeys.customMade.notificationName,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.addValueChangeObserver(notification:)),
                                               name: DefaultsKeys.distributor.notificationName,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.addValueChangeObserver(notification:)),
                                               name: DefaultsKeys.production.notificationName,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.addValueChangeObserver(notification:)),
                                               name: DefaultsKeys.productedDate.notificationName,
                                               object: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableview.dataSource = self
        self.tableview.delegate = self
        let idx = self.navigationController!.viewControllers.index(of: self)! - 1
        self.navigationController?.viewControllers.remove(at: idx)
        self.addObserves()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
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

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == (self.configurationDataIterms.count - 1) { return }
        let show = { [weak self] in
            guard let `self` = self else { return }
            self.picker = [HardwareVersionPickerView.self, SourcePickerView.self, CustomTypePickerView.self, ManufacturerPickerView.self][indexPath.row].init()
            self.picker?.show(inViewController: self, finished: {
                self.view.isUserInteractionEnabled = true
            })
        }

        if let picker = self.picker {
            self.view.isUserInteractionEnabled = false
            picker.dismiss(finished: {
                show()
            })
        } else {
            show()
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }
}
