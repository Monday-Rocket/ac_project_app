//
//  LabelExtension.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/11/11.
//

import UIKit

extension UILabel {
  func setLineHeight(lineHeight: CGFloat) {
    let style = NSMutableParagraphStyle()
    style.maximumLineHeight = lineHeight
    style.minimumLineHeight = lineHeight
    
    let attributes: [NSAttributedString.Key: Any] = [
      .paragraphStyle: style,
      .baselineOffset: (lineHeight - font.lineHeight)
    ]
    
    let attrString = NSAttributedString(string: self.text ?? "", attributes: attributes)
    self.attributedText = attrString
  }
}
