//
//  LogViewController.swift
//  V3
//
//  Created by Anonymous on 2017/12/26.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import SwiftyTimer

class LogViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    private var logs: [String]? = Logger.shared.logArray

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.dataSource = self
        self.tableView.delegate = self
        NotificationCenter.default.addObserver(self, selector: #selector(self.loggerValueChange(notificaiton:)), name: LoggerValueChangeKey, object: nil)
    }

    @objc
    private func loggerValueChange(notificaiton: Notification) {
        dispatch_to_main {
            if let _ = Logger.shared.logArray {
                self.logs = Logger.shared.logArray
                self.tableView.reloadData()
            }
        }
    }

    // MARK: tableview datasource method
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let logs = self.logs {
            return logs.count
        } else {
            return 1
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let Cell_IDentifier = "Cell_IDentifier"
        let cell: UITableViewCell
        if let reuseCell = tableView.dequeueReusableCell(withIdentifier: Cell_IDentifier) {
            cell = reuseCell
        } else {
            cell = UITableViewCell(style: .default, reuseIdentifier: Cell_IDentifier)
        }
        if let logs = self.logs {
            cell.textLabel?.text = logs[indexPath.row]
            cell.textLabel?.textColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
        } else {
            cell.textLabel?.text = "请连接工装后才查看日志信息"
            cell.textLabel?.textColor = UIColor.red
            cell.textLabel?.font = UIFont.systemFont(ofSize: 18)
            cell.textLabel?.adjustsFontSizeToFitWidth = true
        }
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let _ = self.logs {
            return 44
        }
        return 60
    }
}
