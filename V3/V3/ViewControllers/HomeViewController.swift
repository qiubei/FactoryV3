//
//  HomeViewController.swift
//  V3
//
//  Created by Anonymous on 2018/1/3.
//  Copyright © 2018年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import SVProgressHUD

class HomeViewController: UIViewController {
    private var timer: Timer?

    @IBAction func featureButton(_ sender: UIButton) {
        self.performSegue(withIdentifier: "featureID", sender: self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
