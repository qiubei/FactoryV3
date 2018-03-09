//
//  SystemSelectDeviceViewController.swift
//  V3
//
//  Created by Anonymous on 2018/1/3.
//  Copyright © 2018年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift
import SwiftyTimer
import SVProgressHUD
import PromiseKit

class SystemSelectDeviceViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableview: UITableView!

    @IBAction func scanAction(_ sender: UIBarButtonItem) {
        if sender.title == "扫描" {
            sender.title = "停止"
            self.loadData()
        } else {
            sender.title = "扫描"
            self.stopScan()
        }
    }
    private let manager = SystemTestManager.shared
    private let _disposeBag = DisposeBag()
    private var devices = [Peripheral]()
    private var devicesRssi = [String]()
    private var scanedPeripherals = [ScannedPeripheral]()
    private var selectedPeripheral: Peripheral?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableview.dataSource = self
        self.tableview.delegate = self
    }

    private var timer: Timer?
    private func loadData() {
        self.manager.scan()
            .observeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }

                if let name = $0.peripheral.name, name.contains("易休") || name.contains("Luuna") || name.contains("Nap") {
                    self.scanedPeripherals.append($0)
                    self.devices.append($0.peripheral)
                    self.devicesRssi.append($0.rssi.stringValue)
                    self.tableview.reloadData()
                    self.timer = Timer.after(2) {
                        if self.devices.count == 1 {
                            self.selectedPeripheral = self.devices[0]
                            self.swipControllerWith(peripheral: self.selectedPeripheral!)
                        }
                    }
                }
            }).disposed(by: _disposeBag)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        self.timer?.invalidate()
        SVProgressHUD.dismiss()
        self.stopScan()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
//        self.loadData()
        if let p = self.manager.connector?.peripheral {
            p.cancelConnection()
                .subscribe {
                    dispatch_to_main {
                        SVProgressHUD.showInfo(withStatus: "连接中断")
                        // TODO: ugly code
                        self.manager.stopTest()
                    }
                }.disposed(by: self._disposeBag)
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let dvc = segue.destination as? SystemTestViewController {
            dvc.peripheral = self.selectedPeripheral
        }
    }

    // tableview datasource method
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.devices.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellIdentifier = "REUSE_CELL_ID"
        let cell: UITableViewCell
        if let reusedCell = tableview.dequeueReusableCell(withIdentifier: cellIdentifier) {
            cell = reusedCell
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: cellIdentifier)
        }
        cell.textLabel?.text = self.devices[indexPath.row].name
        cell.textLabel?.textColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
        cell.detailTextLabel?.text = self.devicesRssi[indexPath.row]
        return cell
    }

    // tableview delegate method

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 1.0
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableview.deselectRow(at: indexPath, animated: true)
        self.timer?.invalidate()
        self.timer = nil
        self.selectedPeripheral = self.devices[indexPath.row]
        SVProgressHUD.show()
        self.swipControllerWith(peripheral: self.devices[indexPath.row])
    }

    private func stopScan() {
        self.manager.stopScan()
        self.devices.removeAll()
        self.devicesRssi.removeAll()
        self.devices = [Peripheral]()
        self.devicesRssi = [String]()
        self.selectedPeripheral = nil
        self.tableview.reloadData()
    }

    private func swipControllerWith(peripheral: Peripheral) {
        self.manager.startTestWith(peripheral: peripheral).then { () -> () in
            self.performSegue(withIdentifier: "systemResultID", sender: self)
            }.catch { (error) in
                print(error)
                SVProgressHUD.showError(withStatus: "设备连接失败")
        }
    }
}
