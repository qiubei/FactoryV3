//
//  PickerView.swift
//  V2
//
//  Created by PointerFLY on 10/05/2017.
//  Copyright © 2017 EnterTech. All rights reserved.
//

import UIKit

class PickerView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.white
        layout()
        loadEvents()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(inViewController: UIViewController, finished: (() -> Void)? = nil) {
        inViewController.view.addSubview(self)
        self.frame = CGRect(x: 0, y: inViewController.view.bounds.height, width: inViewController.view.bounds.width, height: 220)
        UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: {
            self.frame = CGRect(x: 0, y: self.frame.origin.y - self.frame.height, width: self.frame.width, height: self.frame.height)
        }, completion: { _ in
            finished?()
        })
    }

    func dismiss(finished: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.25, delay: 0, options: [], animations: {
            self.frame = CGRect(x: 0, y: self.frame.origin.y + self.frame.height, width: self.frame.width, height: self.frame.height)
        }, completion: { _ in
            self.removeFromSuperview()
            finished?()
        })
    }

    private func loadEvents() {
        _cancelButton.bk_addEventHandler({ [weak self] _ in
            self?.dismiss()
        }, for: .touchUpInside)
    }

    private func layout() {
        self.addSubview(_cancelButton)
        self.addSubview(_saveButton)
        self.addSubview(_titleLabel)
        self.addSubview(_pickerView)
        _cancelButton.snp.makeConstraints {
            $0.left.equalTo(self).offset(12)
            $0.top.equalTo(self).offset(4)
            $0.width.equalTo(44)
            $0.height.equalTo(36)
        }
        _saveButton.snp.makeConstraints {
            $0.right.equalTo(self).offset(-12)
            $0.top.equalTo(self).offset(4)
            $0.width.equalTo(44)
            $0.height.equalTo(36)
        }
        _titleLabel.snp.makeConstraints {
            $0.top.equalTo(self).offset(8)
            $0.left.equalTo(_cancelButton.snp.right)
            $0.right.equalTo(_saveButton.snp.left)
            $0.height.equalTo(20)
        }
        _pickerView.snp.makeConstraints {
            $0.left.equalTo(self).offset(30)
            $0.right.equalTo(self).offset(-30)
            $0.bottom.equalTo(self).offset(-16)
            $0.top.equalTo(_cancelButton.snp.bottom)
        }
    }

    let _line: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.gray
        return view
    }()

    let _pickerView: UIPickerView = {
        let view = UIPickerView()
        return view
    }()

    let _cancelButton: UIButton = {
        let button = UIButton()
        button.setTitle("取消", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        return button
    }()

    let _saveButton: UIButton = {
        let button = UIButton()
        button.setTitle("保存", for: .normal)
        button.setTitleColor(UIColor.black, for: .normal)
        return button
    }()

    let _titleLabel: UILabel = {
        let label = UILabel()
        label.text = "生产日期"
        label.textColor = UIColor.lightGray
        label.textAlignment = .center
        return label
    }()
}
