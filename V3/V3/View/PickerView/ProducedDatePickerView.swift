//
//  ProducedDatePickerView.swift
//  V2
//
//  Created by PointerFLY on 10/05/2017.
//  Copyright © 2017 EnterTech. All rights reserved.
//

import UIKit

class ProducedDatePickerView: PickerView, UIPickerViewDataSource, UIPickerViewDelegate {

    override init(frame: CGRect) {
        super.init(frame: frame)
        _titleLabel.text = "生产日期"
        _pickerView.dataSource = self
        _pickerView.delegate = self

        _saveButton.bk_addEventHandler({ [weak self] _ in
            guard let `self` = self else { return }
            // TODO: 待实现
//            let one = self._years[self._pickerView.selectedRow(inComponent: 0)]
//            let two = self._months[self._pickerView.selectedRow(inComponent: 1)]
//            let three = self._days[self._pickerView.selectedRow(inComponent: 2)]
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
        switch component {
        case 0: return _years.count
        case 1: return _months.count
        case 2: return _days.count
        default: return 0
        }
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch component {
        case 0: return "20" + String(_years[row])
        case 1: return _months[row]
        case 2: return _days[row]
        default: return nil
        }
    }

    private let _years: [String] = {
        var data = [String](repeating: "", count: 4)
        for i in 0..<data.count {
            let element = String(format: "%.2d", i + 18)
            data[i] = element
        }
        return data
    }()

    private let _months: [String] = {
        var data = [String](repeating: "", count: 12)
        for i in 0..<data.count {
            let element = String(format: "%.2d", i + 1)
            data[i] = element
        }
        return data
    }()

    private let _days: [String] = {
        var data = [String](repeating: "", count: 31)
        for i in 0..<data.count {
            let element = String(format: "%.2d", i + 1)
            data[i] = element
        }
        return data
    }()
}
