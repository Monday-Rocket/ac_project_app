//
//  Utils.swift
//  Extension
//
//  Created by Kangmin Jin on 2022/11/09.
//

import Foundation

extension Date {
  static func ISOStringFromDate(date: Date) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
    
    return dateFormatter.string(from: date).appending("Z")
  }
  
  static func dateFromISOString(string: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    return dateFormatter.date(from: string)
  }
}

extension URL {
  func resolve(_ relativePath: String?) -> String {
    if let path = relativePath {
      if path.starts(with: "http://") || path.starts(with: "https://") {
        return path
      }
      if path.starts(with: "//") {
        return (self.scheme ?? "http") + ":" + path
      }
    }
    return ""
  }
}
