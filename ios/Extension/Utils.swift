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
    dateFormatter.timeZone = .autoupdatingCurrent
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    
    return dateFormatter.string(from: date).appending("Z")
  }
  
  static func dateFromISOString(string: String) -> Date? {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "en_US_POSIX")
    dateFormatter.timeZone = TimeZone.autoupdatingCurrent
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
    
    return dateFormatter.date(from: string)
  }
}
