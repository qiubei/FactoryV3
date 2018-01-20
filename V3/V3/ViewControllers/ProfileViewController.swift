//
//  ProfileViewController.swift
//  V3
//
//  Created by Anonymous on 2018/1/19.
//  Copyright © 2018年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit

class ProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!

    private var iterms: [String: String] {
        let appVersion = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        return ["App 版本号": appVersion]
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
    }

    // tableview datasoure
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return iterms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell_identifier = "cell_identifier"
        let cell: UITableViewCell
        if let reuseCell = tableView.dequeueReusableCell(withIdentifier: cell_identifier) {
            cell = reuseCell
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: cell_identifier)
        }

        for (key, value) in self.iterms {
            cell.textLabel?.text = key
            cell.detailTextLabel?.text = value
        }
        return cell
    }
}
