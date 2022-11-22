//
//  Color.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/11/09.
//

import Foundation
import UIKit

extension UIColor {
  convenience init(red: Int, green: Int, blue: Int) {
    assert(red >= 0 && red <= 255, "Invalid red component")
    assert(green >= 0 && green <= 255, "Invalid green component")
    assert(blue >= 0 && blue <= 255, "Invalid blue component")
    
    self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
  }
  
  convenience init(rgb: Int) {
    self.init(
      red: (rgb >> 16) & 0xFF,
      green: (rgb >> 8) & 0xFF,
      blue: rgb & 0xFF
    )
  }
  
  // MARK: - PRIMARY
  static var primary600: UIColor {
    return UIColor(rgb: 0x804DFF)
  }
  
  // MARK: - Button
  static var secondary: UIColor {
    return UIColor(rgb: 0xC8BFFF)
  }
  
  // MARK: - GREY
  static var grey300: UIColor {
    return UIColor(rgb: 0xCFD4DE)
  }
  
  static var grey800: UIColor {
    return UIColor(rgb: 0x30343E)
  }
}
