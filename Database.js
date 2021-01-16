
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

function dbReadAllToListModel(orderQ, limit)
{
    var db = dbGetHandle()

    var limitQ = "";
    if (limit > 0) {
        limitQ = " limit " + limit;
    }

    db.transaction(function (tx) {
        var results = tx.executeSql(
                    'SELECT rowid,' + tracksSchemaFields.join(',') +
            ' FROM ' + dbTracksTableName +
            ' order by rowid ' + orderQ + limit)
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

function dbRead(orderQ, limit)
{
    var db = dbGetHandle()

    var limitQ = "";
    if (limit > 0) {
        limitQ = " limit " + limit;
    }

    var out = [];
    db.transaction(function (tx) {
        var results = tx.executeSql(
            'SELECT rowid,' + tracksSchemaFields.join(',') +
            ' FROM ' + dbTracksTableName +
            ' ORDER BY rowid ' + orderQ + limitQ)

        for (var i = 0; i < results.rows.length; i++) {
            out.append({
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
    return out;
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

function dbDeleteRows(Prowids)
{
    var db = dbGetHandle()
    db.transaction(function (tx) {
        for (var i = 0; i < Prowids.length; i++) {
            tx.executeSql('delete from ' + dbTracksTableName + ' where rowid = ?', [Prowids[i]])
        }
    })
}