/****************************************************************************
**
** Copyright (C) 2017 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the documentation of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

const dbName = "Cat_Tracks_DB";
const dbEstimatedSize = 1000000 * 100; // 100 MB -> 100000000 bytes
const dbVersion = "0";
const dbDescription = "for cats track em";
const dbTracksTableName = "cat_tracks";

const tracksSchema = [
             'timestamp text',
             'longitude numeric',
             'latitude numeric',
             'altitude numeric',
             'direction numeric',
             'horizontal_accuracy numeric',
             'vertical_accuracy numeric',
             'speed numeric',
             'vertical_speed numeric',
             ];

// tracksSchemaQ is used for SQL insert syntax.
var tracksSchemaQ = tracksSchema.map(function(el) {return "?"});
var tracksSchemaFields = tracksSchema.map(function(el) {return el.substring(0, el.indexOf(' '))});

function dbInit()
{
    var db = LocalStorage.openDatabaseSync(dbName, dbVersion, dbDescription, dbEstimatedSize) //
    try {
        db.transaction(function (tx) {
            /*
              https://www.sqlite.org/datatype3.html
    TEXT
    NUMERIC
    INTEGER
    REAL
    BLOB
            */
//            tx.executeSql('DROP TABLE IF EXISTS ' + dbTracksTableName)
            tx.executeSql('CREATE TABLE IF NOT EXISTS ' + dbTracksTableName + ' (' + tracksSchema.join(',') + ')')
        })
        console.log("Created database", dbTracksTableName);
    } catch (err) {
        console.log("Error creating table in database: " + dbTracksTableName + " " + err);
    };
}

function dbGetHandle()
{
    try {
        var db = LocalStorage.openDatabaseSync(dbName, dbVersion, dbDescription, dbEstimatedSize)
    } catch (err) {
        console.log("Error opening database: " + dbTracksTableName + " " + err);
    }
    return db
}

function dbInsert(trackPoint)
{
    var db = dbGetHandle()
    var rowid = 0;
    db.transaction(function (tx) {
        tx.executeSql('INSERT INTO ' + dbTracksTableName + ' VALUES(' + tracksSchemaQ.join(',') + ')',
                      [
                          new Date(trackPoint.timestamp).toISOString(),
                          trackPoint.longitude,
                          trackPoint.latitude,
                          trackPoint.altitude,
                          trackPoint.direction,
                          trackPoint.horizontal_accuracy,
                          trackPoint.vertical_accuracy,
                          trackPoint.speed,
                          trackPoint.vertical_speed,
                      ])
        var result = tx.executeSql('SELECT last_insert_rowid()')
        rowid = result.insertId
    })
    return rowid;
}

function dbReadAll(orderQ, limit)
{
    var db = dbGetHandle()

    var limitQ = "";
    if (limit > 0) {
        limitQ = " limit " + limit;
    }

    db.transaction(function (tx) {
        var results = tx.executeSql(
                    'SELECT rowid,' + tracksSchemaFields.join(',') + ' FROM ' + dbTracksTableName + ' order by rowid ' + orderQ + limitQ)
        for (var i = 0; i < results.rows.length; i++) {
            listModel.append({
                                id: results.rows.item(i).rowid,
                                timestamp: results.rows.item(i).timestamp,
                                longitude: results.rows.item(i).longitude,
                                latitude: results.rows.item(i).latitude,
                                altitude: results.rows.item(i).altitude,
                                direction: results.rows.item(i).direction,
                                horizontal_accuracy: results.rows.item(i).horizontal_accuracy,
                                vertical_accuracy: results.rows.item(i).vertical_accuracy,
                                speed: results.rows.item(i).speed,
                                vertical_speed: results.rows.item(i).vertical_speed
                             })
        }
    })
}

function dbCount() {
    var db = dbGetHandle()
    var count = 0
    db.transaction(function(tx) {
        var result = tx.executeSql('SELECT COUNT(rowid) as count FROM ' + dbTracksTableName)
        count = result.rows.item(0).count;
    })
    return count;
}
