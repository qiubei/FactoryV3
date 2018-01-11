//
//  ViewController.swift
//  V3
//
//  Created by Anonymous on 2017/12/20.
//  Copyright © 2017年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import RxBluetoothKit
import RxSwift

class BoardSelectedViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var startButton: UIButton!

    private var peripherals = [Peripheral]()
    private let manager = TestFlowManager()
    private let _disposeBag = DisposeBag()


    override func viewDidLoad() {
        super.viewDidLoad()
        self.startButton.backgroundColor = UIColor.lightGray
        tableView.dataSource = self
        tableView.delegate = self
        self.scanPeripherals()
    }

//    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(true)
//        self.startButton.backgroundColor = UIColor.lightGray
//        self.peripherals = [Peripheral]()
//        self.tableView.reloadData()
//        self.manager.stopScan()
//        self.selectedIndexPath = nil
//        self.selectedPeripheral = nil
//        self.scanPeripherals()
//    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "testIdentifier" {
            let destinationVC = segue.destination as! BoardTestViewController
            destinationVC.manager = self.manager
            destinationVC.fixtureToolPeripheral = self.selectedPeripheral
        }
    }

    private func scanPeripherals() {
        self.manager.scan()
            .subscribe(onNext: { [weak self] in
                guard let `self` = self else { return }
                if let name = $0.peripheral.name {
                    if name.contains("NAP") {
                        self.peripherals.append($0.peripheral)
                        dispatch_to_main {
                            self.tableView.reloadData()
                        }
                    }
                }
            }).disposed(by: _disposeBag)
    }

    // tableview datasource method
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return peripherals.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let identifierID = "identifierID"
        let cell: UITableViewCell
        if let dequeueCell = tableView.dequeueReusableCell(withIdentifier: identifierID) {
            cell = dequeueCell
        } else {
            cell = UITableViewCell(style: .value1, reuseIdentifier: identifierID)
        }
        cell.textLabel?.text = peripherals[indexPath.row].name
        cell.textLabel?.textColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
        cell.detailTextLabel?.textColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
        if let indexp = self.selectedIndexPath, indexp == indexPath {
            cell.detailTextLabel?.text = "已选中"
        } else {
            cell.detailTextLabel?.text = "连接"
        }
        return cell
    }

    private var selectedPeripheral: Peripheral?
    private var selectedIndexPath: IndexPath?

    // tableview delegate method
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        self.selectedIndexPath = indexPath
        self.selectedPeripheral = self.peripherals[indexPath.row]
        self.tableView.reloadData()
        self.startButton.isEnabled = true
        self.startButton.backgroundColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
    }
}
