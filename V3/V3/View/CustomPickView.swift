//
//  CustomPickView.swift
//  V3
//
//  Created by Anonymous on 2018/1/14.
//  Copyright © 2018年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import SnapKit

class CustomPickView: UIView {

    let pickerview: UIPickerView
    var titile: String?

    private var cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("取消", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()

    private var okButton: UIButton = {
        let button = UIButton()
        button.setTitle("确定", for: .normal)
        button.setTitleColor(UIColor.white, for: .normal)
        button.backgroundColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
        button.layer.cornerRadius = 3
        button.clipsToBounds = true
        return button
    }()

    private var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
        label.backgroundColor = UIColor.clear
        return label
    }()

    private var pickerView: UIPickerView = {
        let pickerView = UIPickerView()
        return pickerView
    }()

    init(pickerview: UIPickerView, title: String) {
        self.pickerview = pickerview
        super.init(frame: CGRect())

        self.layoutViews()
        self.loadEvents()
    } 

    typealias block = () -> ()

    func pickerView(okHandler: block, cancelHandler: block) {

    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutViews() {
        self.addSubview(self.cancelButton)
        self.addSubview(self.titleLabel)
        self.addSubview(self.okButton)
        self.addSubview(self.pickerView)


        self.cancelButton.snp.makeConstraints { (make) in
            make.left.equalTo(0)
            make.top.equalTo(0)
            make.height.equalTo(44)
            make.width.equalTo(60)
        }

        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.cancelButton.snp.right)
            make.right.equalTo(self.okButton.snp.left)
            make.top.equalTo(0)
            make.height.equalTo(self.cancelButton.snp.height)
        }

        self.okButton.snp.makeConstraints { (make) in
            make.top.equalTo(0)
            make.right.equalTo(0)
            make.height.equalTo(self.cancelButton.snp.height)
            make.width.equalTo(self.cancelButton.snp.width)
        }

        self.pickerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.bottom.equalTo(0)
            make.left.equalTo(0)
            make.right.equalTo(0)
        }
    }

    private func loadEvents() {
        
    }
}
