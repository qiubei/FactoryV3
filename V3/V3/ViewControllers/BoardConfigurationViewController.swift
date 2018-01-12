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

class BoardConfigurationViewController: UITableViewController {

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

    override func viewDidLoad() {
        super.viewDidLoad()

        let idx = self.navigationController!.viewControllers.index(of: self)! - 1
        self.navigationController?.viewControllers.remove(at: idx)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.configurationDataIterms.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
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

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == 4 {
            if self.datePicker == nil {
                self.addDatePickerView()
            } else {
                self.datePicker?.isHidden = false
            }
        } else {
            self.datePicker?.isHidden = true
            self.addAlertSheet(title: self.configurationTitleItems[indexPath.row], self.hardwareVersion) { (textField) in
                self.configurationDataIterms[indexPath.row] = textField.text!
                tableView.reloadData()
            }
        }
    }

    private func addAlertSheet(title: String,_ placeHolder: String, block: @escaping TextFieldBlock) {
        var _textField: UITextField?
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .alert)
        alertController.addTextField { (textField) in
            textField.keyboardType = .numberPad
            textField.becomeFirstResponder()
            _textField = textField
        }
        let okAction = UIAlertAction(title: "修改", style: .default) { (alert) in
            block(_textField!)
        }
        let cancelAction = UIAlertAction(title: "取消", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }

    private var datePicker: UIDatePicker?
    private func addDatePickerView() {
        let height = self.view.bounds.height * 0.35
        let frame = CGRect(x: 0, y: self.view.bounds.height - height, width: self.view.bounds.width, height: height)
        self.datePicker = UIDatePicker(frame: frame)
        self.datePicker!.datePickerMode = .date
        self.datePicker!.locale = Locale(identifier: "zh_CN")
        self.datePicker!.addTarget(self, action: #selector(self.dateValueChange(datePicker:)), for: .valueChanged)
        self.datePicker!.setDate(Date(), animated: true)
        self.view.addSubview(datePicker!)
    }

    @objc private func dateValueChange(datePicker: UIDatePicker){
        let formatterString = "yyMMdd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = formatterString
        self.configurationDataIterms[4] = dateFormatter.string(from: datePicker.date)
        Defaults[.productedDate] = self.configurationDataIterms[4]
        self.tableView.reloadData()
    }
}
