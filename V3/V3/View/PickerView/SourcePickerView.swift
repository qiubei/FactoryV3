//
//  SourcePickerView.swift
//  V2
//
//  Created by PointerFLY on 10/05/2017.
//  Copyright © 2017 EnterTech. All rights reserved.
//

import UIKit

class SourcePickerView: PickerView, UIPickerViewDataSource, UIPickerViewDelegate {

    override init(frame: CGRect) {
        super.init(frame: frame)
        _titleLabel.text = "渠道"
        _pickerView.dataSource = self
        _pickerView.delegate = self

        _saveButton.bk_addEventHandler({ [weak self] _ in
            guard let `self` = self else { return }
            var info = DeviceInfo.shared.distributor
            let one = self._data[self._pickerView.selectedRow(inComponent: 0)]
            let two = self._data[self._pickerView.selectedRow(inComponent: 1)]
            let three = self._data[self._pickerView.selectedRow(inComponent: 2)]
            info = String(format: "%d%d%d", one, two, three)
            DeviceInfo.shared.distributor = info
            self.dismiss()
            }, for: .touchUpInside)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 3
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 10
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let number = _data[row]
        return String(number)
    }

    private let _data = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9]
}
