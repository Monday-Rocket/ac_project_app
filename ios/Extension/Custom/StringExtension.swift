//
//  StringExtension.swift
//  Extension
//
//  Created by Kangmin Jin on 2023/01/07.
//

import Foundation

extension String {
  
  init?(htmlEncodedString: String) {
    
    guard let data = htmlEncodedString.data(using: .utf8) else {
      return nil
    }
    
    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
      .documentType: NSAttributedString.DocumentType.html,
      .characterEncoding: String.Encoding.utf8.rawValue
    ]
    
    guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
      return nil
    }
    
    self.init(attributedString.string)
    
  }
  
}
