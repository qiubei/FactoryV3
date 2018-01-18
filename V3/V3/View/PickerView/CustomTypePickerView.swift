//
//  CustomTypePickerView.swift
//  V2
//
//  Created by PointerFLY on 10/05/2017.
//  Copyright © 2017 EnterTech. All rights reserved.
//

import UIKit

class CustomTypePickerView: PickerView, UIPickerViewDataSource, UIPickerViewDelegate {

    override init(frame: CGRect) {
        super.init(frame: frame)
        _titleLabel.text = "定制"
        _pickerView.dataSource = self
        _pickerView.delegate = self

        _saveButton.bk_addEventHandler({ [weak self] _ in
            guard let `self` = self else { return }
            var info = DeviceInfo.shared.customMade
            info = self._data[self._pickerView.selectedRow(inComponent: 0)]
            DeviceInfo.shared.customMade = info
            self.dismiss()
        }, for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return _data.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return _data[row]
    }

    private let _data: [String] = {
        var data = [String](repeating: "", count: 100)
        for i in 0..<data.count {
            let element = String(format: "%.2d", i)
            data[i] = element
        }
        return data
    }()
}
