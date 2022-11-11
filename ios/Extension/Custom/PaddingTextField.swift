//
//  PaddingTextField.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/11/11.
//

import Foundation
import UIKit

class PaddingTextField: UITextField {
  var textPadding = UIEdgeInsets(
    top: 15,
    left: 16,
    bottom: 15,
    right: 16
  )
  
  override func textRect(forBounds bounds: CGRect) -> CGRect {
    let rect = super.textRect(forBounds: bounds)
    return rect.inset(by: textPadding)
  }
  
  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    let rect = super.editingRect(forBounds: bounds)
    return rect.inset(by: textPadding)
  }
}
