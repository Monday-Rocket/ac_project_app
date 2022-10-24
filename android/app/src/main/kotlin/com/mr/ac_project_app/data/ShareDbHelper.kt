package com.mr.ac_project_app.data

import android.content.Context
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper

class ShareDbHelper(context: Context) :
    SQLiteOpenHelper(context, DATABASE_NAME, null, DATABASE_VERSION) {
    override fun onCreate(db: SQLiteDatabase) {
        db.execSQL(
            "create table ${ShareContract.FolderTempEntry.table}( " +
                    "seq int primary key, " +
                    "name varchar(20) not null, " +
                    "visible boolean not null default 1 " +
                    ");"
        )
        db.execSQL(
            "create table ${ShareContract.LinkTempEntry.table}( " +
                    "seq int primary key, " +
                    "link varchar(2000) not null, " +
                    "comment varchar(300), " +
                    "folder_seq int(11) " +
                    ");"
        )
    }

    override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
        // This database is only a cache for online data, so its upgrade policy is
        // to simply to discard the data and start over
        db.execSQL("drop table folder_temp")
        db.execSQL("drop table link_temp")
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