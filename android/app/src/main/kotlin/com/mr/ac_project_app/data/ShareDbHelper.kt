package com.mr.ac_project_app.data

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class ShareDbHelper(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL("""
            create table if not exists ${ShareContract.Folder.table} (
                ${ShareContract.Folder.seq} int primary key,
                ${ShareContract.Folder.folderName} varchar(200) not null unique,
                ${ShareContract.Folder.visible} boolean not null default 1,
                ${ShareContract.Folder.imageLink} varchar(2000),
                ${ShareContract.Folder.time} timestamp default current_timestamp not null
            );
            """
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // This database is only a cache for online data, so its upgrade policy is
        // to simply to discard the data and start over
        db.execSQL("drop table ${ShareContract.Folder.table}")
        onCreate(db)
    }

    override fun onDowngrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        onUpgrade(db, oldVersion, newVersion)
    }

    companion object {
        // If you change the database schema, you must increment the database version.
        const val DATABASE_VERSION = 1
        const val DATABASE_NAME = "share.db"
    }
}