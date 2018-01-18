//
//  CustomPickView.swift
//  V3
//
//  Created by Anonymous on 2018/1/14.
//  Copyright © 2018年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit
import SnapKit
import BlocksKit

class CustomPickView: UIView {
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
        button.setTitle("修改", for: .normal)
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

    var pickerView: UIPickerView = {
        let pickerView = UIPickerView()

        return pickerView
    }()

    private var cancelBlock: block?
    private var okBlock: block?
    private let title: String
    init(title: String) {
        self.title = title
        super.init(frame: CGRect())
        self.titleLabel.text = self.title
        self.backgroundColor = UIColor.white
        self.layoutViews()
        self.loadEvents()
    }

    func handerEventWith(cancelHandler: block?, okHandler: block?) {
//        self.cancelBlock = cancelHandler?()
//        self.okBlock = okHandler?()
    }

    typealias block = () -> ()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutViews() {
        self.addSubview(self.cancelButton)
        self.addSubview(self.titleLabel)
        self.addSubview(self.okButton)
        self.addSubview(self.pickerView)


        self.cancelButton.snp.makeConstraints { (make) in
            make.left.equalTo(8)
            make.top.equalTo(8)
            make.height.equalTo(36)
            make.width.equalTo(60)
        }

        self.titleLabel.snp.makeConstraints { (make) in
            make.left.equalTo(self.cancelButton.snp.right)
            make.right.equalTo(self.okButton.snp.left)
            make.top.equalTo(4)
            make.height.equalTo(self.cancelButton.snp.height)
        }

        self.okButton.snp.makeConstraints { (make) in
            make.top.equalTo(8)
            make.right.equalTo(-8)
            make.height.equalTo(self.cancelButton.snp.height)
            make.width.equalTo(self.cancelButton.snp.width)
        }

        self.pickerView.snp.makeConstraints { (make) in
            make.top.equalTo(self.titleLabel.snp.bottom)
            make.left.equalTo(self.cancelButton.snp.right)
            make.right.equalTo(self.okButton.snp.left)
            make.bottom.equalTo(0)
        }
    }

    private func loadEvents() {
        self.cancelButton.bk_addEventHandler({ [weak self] _ in
            guard let `self` = self else { return }
            self.cancelBlock?()
            self.dismissView(animated: true)
        }, for: .touchUpInside)

        self.okButton.bk_addEventHandler({[weak self] _ in
            guard let `self` = self else { return }
            self.okBlock?()
            self.dismissView(animated: true)
         }, for: .touchUpInside)
    }

    private func dismissView(animated: Bool) {
        if animated {

        } else {
        }
//        self.removeFromSuperview()
//        self.isHidden = true
    }
}
