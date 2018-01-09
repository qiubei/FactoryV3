//
//  SystemPasswordViewController.swift
//  V3
//
//  Created by Anonymous on 2018/1/5.
//  Copyright © 2018年 Hangzhou Enter Electronic Technology Co., Ltd. All rights reserved.
//

import UIKit

let DEFAULT_CONFUGRATION_PASSWORD = "0000"

class SystemPasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var passwordTextfield: UITextField!
    @IBOutlet var labelList: [UILabel]!


    private var passwordText: String = ""
    override func viewDidLoad() {
        super.viewDidLoad()
        self.reset()
        self.passwordTextfield.becomeFirstResponder()
        self.passwordTextfield.addTarget(self, action: #selector(self.textFieldAction(textField:)), for: .editingChanged)
        self.passwordTextfield.delegate = self

        for label in labelList {
            label.backgroundColor = UIColor.white
            label.layer.borderColor = #colorLiteral(red: 0.2337238216, green: 0.6367476892, blue: 1, alpha: 1)
            label.layer.borderWidth = 1.0
            label.clipsToBounds = true
            label.font = UIFont.systemFont(ofSize: 18)
            label.textColor = UIColor.black
            label.textAlignment = .center
        }
    }

    @objc
    private func textFieldAction(textField: UITextField) {
        if let text = textField.text {
            if self.passwordText.count == 4 {
                self.reset()
            }
            self.passwordText += text
            for iterm in self.labelList {
                iterm.layer.borderWidth = 1
                if self.passwordText.count == (iterm.tag % 10) {
                    iterm.text = text
                    textField.text = ""
                }
            }
            if self.passwordText == DEFAULT_CONFUGRATION_PASSWORD {
                self.performSegue(withIdentifier: "appConfigurationID", sender: self)
            }
        }
    }

    private func reset() {
        self.passwordTextfield.text = ""
        self.passwordText = ""
        for item in labelList {
            item.text = ""
        }
    }
}
