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
    do {
      let dbPath: String = try FileManager.default.url(
        for: .documentDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: false).appendingPathComponent(databaseName).path
      if sqlite3_open(dbPath, &db) == SQLITE_OK {
        NSLog("Successfully create DB. Path:\(dbPath)")
        
        return db
      }
    } catch {
      NSLog("Error while creating DB - \(error.localizedDescription)")
    }
    
    return nil
  }
  
  
  
  func createTable(){
    
    let query = """
CREATE TABLE IF NOT EXISTS folder(
name VARCHAR(200) PRIMARY KEY,
visible INT NOT NULL DEFAULT 1,
image_link TEXT,
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
  
  func insertData(name: String, visible: Int, image_link : String?) -> Bool {
    
    let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    
    let insertQuery = "INSERT INTO folder (name, visible, image_link) VALUES (?, ?, ?);"
    var statement: OpaquePointer? = nil
    
    if sqlite3_prepare_v2(self.db, insertQuery, -1, &statement, nil) == SQLITE_OK {
      
      sqlite3_bind_text(statement, 1, name, -1, SQLITE_TRANSIENT)
      sqlite3_bind_int(statement, 2, Int32(visible))
      sqlite3_bind_text(statement, 3, image_link, -1, SQLITE_TRANSIENT)
    }
    else {
      NSLog("sqlite binding failure")
      return false
    }
    return sqlite3_step(statement) == SQLITE_DONE
  }
  
  func readData() -> [Folder] {
    let query: String = "SELECT * FROM folder ORDER BY TIME DESC;"
    var statement: OpaquePointer? = nil
    // 아래는 [MyModel]? 이 되면 값이 안 들어간다.
    // Nil을 인식하지 못하는 것으로..
    var result: [Folder] = []
    
    if sqlite3_prepare(self.db, query, -1, &statement, nil) != SQLITE_OK {
      let errorMessage = String(cString: sqlite3_errmsg(db)!)
      NSLog("error while prepare: \(errorMessage)")
      return result
    }
    while sqlite3_step(statement) == SQLITE_ROW {
      let name = String(cString: sqlite3_column_text(statement, 0)) // 결과의 0번째 테이블 값
      let visible =  sqlite3_column_int(statement, 1)// 결과의 1번째 테이블 값.
      let image_link = String(cString: sqlite3_column_text(statement, 2)) // 결과의 2번째 테이블 값.
      
      result.append(Folder(name: String(name), visible: Int(visible), image_link: String(image_link)))
    }
    sqlite3_finalize(statement)
    NSLog("🎁 \(result)")
    
    return result
  }
  
  func updateData(name: String, visible: Int, imageLink : String?) {
    var statement: OpaquePointer?
    
    let queryString = "UPDATE folder SET name = '\(name)', visible = \(visible), image_link = '\(imageLink ?? "")' WHERE name == '\(name)'"
    
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
    
    let queryString = "UPDATE folder SET image_link = '\(imageLink ?? "")' WHERE name == '\(name)'"
    
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
