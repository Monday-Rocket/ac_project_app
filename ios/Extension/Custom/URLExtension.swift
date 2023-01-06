//
//  URLExtension.swift
//  Extension
//
//  Created by Kangmin Jin on 2023/01/06.
//

import Foundation

extension URL {
  public var queryParameters: [String: String]? {
    guard
      let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
      let queryItems = components.queryItems else { return nil }
    return queryItems.reduce(into: [String: String]()) { (result, item) in
      result[item.name] = item.value
    }
  }
}
