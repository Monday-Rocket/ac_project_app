  //
  //  DBHelper.swift
  //  Extension
  //
  //  Created by 유재선 on 2022/10/24.
  //

import Foundation
import SQLite3



class DBHelper {
  
  static let shared = DBHelper()
  
  
  var db : OpaquePointer?
  
  let databaseName = "share.db"
  
  init(){
    self.db = createDB()
    createTable()
  }
  
  deinit {
    sqlite3_close(db)
  }
  
  private func createDB() -> OpaquePointer? {
    var db: OpaquePointer? = nil
    let url = FileManager
      .default
      .containerURL(
        forSecurityApplicationGroupIdentifier: "group.com.mr.acProjectApp.Share"
      )
    let dbPath: String = url!.appendingPathComponent("share.db").path
    
    if sqlite3_open(dbPath, &db) == SQLITE_OK {
      NSLog("Successfully create DB. Path:\(dbPath)")
      
      return db
    }
    
    return nil
  }
  
  
  
  func createTable(){
    
    let query = """
CREATE TABLE IF NOT EXISTS folder(
  seq INT PRIMARY KEY,
  name VARCHAR(200) UNIQUE,
  imageLink VARCHAR(2000),
  time TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
);
"""
    
    var statement : OpaquePointer? = nil
    if sqlite3_prepare_v2(self.db, query, -1, &statement, nil) == SQLITE_OK {
      if sqlite3_step(statement) == SQLITE_DONE {
        NSLog("\n\n\n create : Creating table has been succesfully done. db: \(String(describing: self.db))")
        
      }
      else {
        let errorMessage = String(cString: sqlite3_errmsg(db))
        NSLog("\n\n\n create : sqlte3_step failure while creating table: \(errorMessage)")
      }
    }
    else {
      let errorMessage = String(cString: sqlite3_errmsg(self.db))
      NSLog("\n\n\n create : sqlite3_prepare failure while creating table: \(errorMessage)")
    }
    
    sqlite3_finalize(statement)
  }
  
  func insertData(name: String, imageLink : String?) -> Bool {

    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)


    let insertQuery = "INSERT INTO folder (name, imageLink) VALUES (?, ?);"
    var statement: OpaquePointer? = nil

    if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {

      sqlite3_bind_text(statement, 1, name, -1, SQLITE_TRANSIENT)
      sqlite3_bind_text(statement, 2, imageLink, -1, SQLITE_TRANSIENT)
    }
    else {
      NSLog("sqlite binding failure")
      return false
    }
    return sqlite3_step(statement) == SQLITE_DONE
  }
  
  func readData() -> [Folder] {
    let query: String = "SELECT name, imageLink FROM folder ORDER BY TIME DESC;"
    var statement: OpaquePointer? = nil
    var result: [Folder] = []

    if sqlite3_prepare(self.db, query, -1, &statement, nil) != SQLITE_OK {
      let errorMessage = String(cString: sqlite3_errmsg(db)!)
      NSLog("error while prepare: \(errorMessage)")
      return result
    }
    while sqlite3_step(statement) == SQLITE_ROW {
      let name = String(cString: sqlite3_column_text(statement, 0))

      var imageLink = ""

      if let temp = sqlite3_column_text(statement, 1) {
        imageLink = String(cString: temp)
      }

      result.append(Folder(name: String(name), imageLink: String(imageLink)))
    }
    sqlite3_finalize(statement)
    NSLog("🎁 \(result)")

    return result
  }
  
  func updateData(name: String, imageLink : String?) {
    var statement: OpaquePointer?

    let queryString = "UPDATE folder SET name = '\(name)', imageLink = '\(imageLink ?? "")' WHERE name == '\(name)'"
    
      // 쿼리 준비.
    if sqlite3_prepare(db, queryString, -1, &statement, nil) != SQLITE_OK {
      onSQLErrorPrintErrorMessage(db)
      
      return
    }
      // 쿼리 실행.
    if sqlite3_step(statement) != SQLITE_DONE {
      onSQLErrorPrintErrorMessage(db)
      return
    }
    
    NSLog("Update has been successfully done")
  }
  
  func updateFolderImage(_ name: String, _ imageLink: String?) {
    var statement: OpaquePointer?
    
    let queryString = "UPDATE folder SET imageLink = '\(imageLink ?? "")' WHERE name == '\(name)'"
    
      // 쿼리 준비.
    if sqlite3_prepare(db, queryString, -1, &statement, nil) != SQLITE_OK {
      onSQLErrorPrintErrorMessage(db)
      return
    }
      // 쿼리 실행.
    if sqlite3_step(statement) != SQLITE_DONE {
      onSQLErrorPrintErrorMessage(db)
      return
    }
    
    NSLog("Update folder Image has been successfully done")
  }
  
  private func onSQLErrorPrintErrorMessage(_ db: OpaquePointer?) {
    let errorMessage = String(cString: sqlite3_errmsg(db))
    NSLog("Error preparing update: \(errorMessage)")
    return
  }
  
  
  func dbClose(){
    sqlite3_close(db)
  }
}
