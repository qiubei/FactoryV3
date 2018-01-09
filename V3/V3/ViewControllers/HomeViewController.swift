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
    override func viewDidLoad() {
        super.viewDidLoad()

        SVProgressHUD.show(UIImage(named: "pass.png")!, status: "测试通过" )

    }
}
