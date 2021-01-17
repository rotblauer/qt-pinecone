import QtQuick 2.14

import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

import QtQuick.LocalStorage 2.10

import QtQuick.Layouts 1.11
import QtQuick.Window 2.2

import "Database.js" as DBJS
import "API.js" as API
import "secrets.js" as SECRETS
import Qt.labs.settings 1.0


ApplicationWindow {
    id: window
    visible: true
    width: 400 // Screen.width
    height: 800 // Screen.height

    Material.theme: Material.Dark
    Material.accent: Material.Purple

    property int pushBatchSize: 100
    property int pushBatchEvery: 100

    Settings {
        property alias x: window.x
        property alias y: window.y
        property alias width: window.width
        property alias height: window.height
        property alias pushBatchSize: window.pushBatchSize
        property alias pushBatchEvery: window.pushBatchEvery
    }

    function withPrec(value, prec) {
        if (!value) return null;
        return Math.round(value * prec) / prec;
    }

    function saveValidPosition(position) {
        var precLL = 10000000;  // Math.pow(10, 7); // lng,lat
        var precVel = 100; // Math.pow(10, 2); // velocities

        var positionObject = {
            timestamp: position.timestamp + "",
            unix_timestamp: withPrec(new Date(position.timestamp).getTime() / 1000, 1),
            longitude: withPrec(position.coordinate.longitude, precLL),
            latitude: withPrec(position.coordinate.latitude, precLL),
            altitude: withPrec(position.coordinate.altitude, precVel) || 0,
            direction: Math.round(position.direction) || -1,
            horizontal_accuracy: withPrec(position.horizontal_accuracy, precVel) || -1,
            vertical_accuracy: withPrec(position.vertical_accuracy, precVel) || -1,
            speed: withPrec(position.speed, precVel) || -1,
            vertical_speed: withPrec(position.vertical_speed, precVel) || -1
        };

        var rowid = parseInt(DBJS.dbInsert(positionObject), 10);
        if (rowid) {
            console.log("Save OK", rowid, JSON.stringify(positionObject));

            // Manually insert a COPY of the record into the listview model.
            listView.model.insert(0, positionObject);
            if (listView.model.count > 30) {
                listView.model.remove(30, listView.model.count - 30);
            }

            listView.currentIndex = 0;
            listView.forceLayout()

            updatePointsQueuedDisplay();
        }
        return rowid;
    }

    function point2GeoJSON(point) {
        /*
        {
          "type": "Feature",
          "geometry": {
            "type": "Point",
            "coordinates": [125.6, 10.1]
          },
          "properties": {
            "name": "Dinagat Islands"
          }
        }
            props["UUID"] = trackPointCurrent.Uuid
            props["Name"] = trackPointCurrent.Name
            props["Time"] = trackPointCurrent.Time
            props["UnixTime"] = trackPointCurrent.Time.Unix()
            props["Version"] = trackPointCurrent.Version
            props["Speed"] = trackPointCurrent.Speed
            props["Elevation"] = trackPointCurrent.Elevation
            props["Heading"] = trackPointCurrent.Heading
            props["Accuracy"] = trackPointCurrent.Accuracy

        */
        var f = {
            "type": "Feature",
            "geometry": {
                "type": "Point",
                "coordinates": [point.longitude, point.latitude]
            },
            "properties": {
                "UUID": SECRETS.appCatOwnerName,
                "Name": SECRETS.appUUID,
                "Version": SECRETS.appVersion,
                "Time": point.timestamp, // this should already by in ISO8601
                "UnixTime": point.unix_timestamp,
                "Speed": point.speed,
                "Heading": point.direction,
                "Accuracy": point.horizontal_accuracy,
            }
        };
        //                 "Elevation": point.altitude === 0 ? null : point.altitude,
        if (point.altitude !== 0) {
            f["properties"]["Elevation"] = point.altitude;
        }
        return f;
    }

    property int pushedN;

    // pushBatching is a recursive (on success) function which attempts to push
    // all entries stored in the database in batches of batchSize.
    // It will abort if the push encounters an error.
    // It updates the push and status displays.
    function pushBatching(batchSize) {
        var entries = DBJS.dbRead('asc', batchSize);
        if (entries.length === 0) {
            console.log("DB empty");
            return;
        }
        var ids = [];
        var geojsonFeatures = [];

        for (var i = 0; i < entries.length; i++) {
            geojsonFeatures.push(point2GeoJSON(entries[i]));
            ids.push(entries[i].id);
        }

        var headers = {};
        headers[SECRETS.appAuthorizationHeaderKey] = SECRETS.appAuthorizationHeaderValue;

        setStatusDisplay(pushStatusText, "warn", "Pushing...");
        API.api_post(SECRETS.appEndpoint, geojsonFeatures, {}, headers, function(status, resp) {

            if (status !== 200) {
                var responseText;
                try {
                    responseText = JSON.stringify(resp);
                } catch (e) {
                    responseText = resp;
                }
                setStatusDisplay(pushStatusText, "error", "Push status: " +  status + " " + responseText);
                return;
            }

            pushedN += entries.length;

            setStatusDisplay(pushStatusText, "info", "Push status: " + status);

            // Once push is confirmed 200, delete em.
            DBJS.dbDeleteRows(ids);

            if (entries.length === batchSize) {
                // Our batch size was met which suggests that there
                // may be more entries left to push.
                // Recursion.
                pushBatching(batchSize);
            }
        });
    }

    function getDBRowsCount() {
        var count = DBJS.dbCount();
        return count;
    }

    function updatePointsQueuedDisplay() {
        var count = getDBRowsCount();
        entriesCount.text = "Q: " + count;
    }

    function setStatusDisplay(item, qualitative, text) {
        // gpsStatusText, pushStatusText
        console.log(qualitative + ": " + text);
        item.font.bold = false
        switch (qualitative) {
        case "info":
            item.color = Material.color(Material.Teal)
            break;
        case "warn":
            item.color = Material.color(Material.Orange)
            break;
        case "error":
            item.color = Material.color(Material.Red)
            item.font.bold = true
            break;
        }
        item.text = text;
    }

    function printableMethod(method) {
        if (method === Positioning.SatellitePositioningMethods)
            return "sat"
        else if (method === Positioning.NoPositioningMethods)
            return "na"
        else if (method === Positioning.NonSatellitePositioningMethods)
            return "nsat"
        else if (method === Positioning.AllPositioningMethods)
            return "a"
        return "source error"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.rightMargin: 0
        anchors.bottomMargin: 0
        anchors.leftMargin: 0
        anchors.topMargin: 0

        GridLayout {
            columns: 3
            Layout.fillWidth: true
            Layout.fillHeight: false
            Text {
                text: "Push every"
            }
            TextInput {
                id: pushBatchEveryInput
                font.pointSize: 12
                Layout.fillWidth: true
                validator: RegularExpressionValidator {
                    regularExpression: /\d+/
                }
                text: window.pushBatchEvery
            }
            Button {
                id: savePushBatchEveryInput
                text: "Save"
                onClicked: {
                    var i = parseInt(pushBatchEveryInput.text);
                    if (pushBatchEveryInput.text === "" || i < 1) {
                        pushBatchEveryInput.text = 1;
                    }
                    window.pushBatchEvery = i;
                }
            }
        }
        GridLayout {
            columns: 3
            Layout.fillWidth: true
            Layout.fillHeight: false
            Text {
                text: "Push batch size"
            }
            TextInput {
                id: pushBatchSizeInput
                font.pointSize: 12
                Layout.fillWidth: true
                validator: RegularExpressionValidator {
                    regularExpression: /\d+/
                }
                text: window.pushBatchSize
            }
            Button {
                id: savePushBatchSizeInput
                text: "Save"
                onClicked: {
                    var i = parseInt(pushBatchSizeInput.text);
                    if (pushBatchSizeInput.text === "" || i < 1) {
                        pushBatchSizeInput.text = 1;
                    }
                    window.pushBatchSize = i;
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            columns: 5
            Text {
                id: positionMethodText
                text: "<POSITIONING METHOD>"
                color: Material.color(Material.Teal)
                Layout.fillWidth: true
            }
            Text {
                id: gpsStatusText
                text: "<GPS STATUS>"
                color: Material.color(Material.Grey)
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
            }
            Text {
                id: entriesCount
                text: "<NUM ENTRIES>"
                color: Material.color(Material.Teal)
                Layout.fillWidth: true
            }
            Text {
                id: pushedCount
                text: pushedN
                color: Material.color(Material.Teal)
                Layout.fillWidth: true
            }
            Text {
                id: pushStatusText
                text: "<PUSH STATUS>"
                color: Material.color(Material.Grey)
                Layout.fillWidth: true
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignRight
            columns: 9
            Text {
                id: table_header_timestamp
                text: "ts"
                Layout.fillWidth: true
            }
            Text {
                id: table_header_longitude
                text: "lon"
                Layout.fillWidth: true
            }
            Text {
                id: table_header_latitude
                text: "lat"
                Layout.fillWidth: true
            }
            Text {
                id: table_header_altitude
                text: "alt"
                Layout.fillWidth: true
            }
            Text {
                id: table_header_direction
                text: "cog"
                Layout.fillWidth: true
            }
            Text {
                id: table_header_horizontal_accuracy
                text: "hacc"
                Layout.fillWidth: true
            }
            Text {
                id: table_header_vertical_accuracy
                text: "vacc"
                Layout.fillWidth: true
            }
            Text {
                id: table_header_speed
                text: "m/s"
                Layout.fillWidth: true
            }
            Text {
                id: table_header_vertical_speed
                text: "vm/s"
                Layout.fillWidth: true
            }
        }


        RowLayout {
            id: rowLayout
            width: 100
            height: 400
            Layout.preferredHeight: 460
            Layout.fillHeight: true
            Layout.fillWidth: true

            ListView {
                id: listView
                Layout.fillWidth: true
                Layout.fillHeight: true

                model: MyModel {}
                delegate: MyDelegate {
                    // onClicked: listView.currentIndex = index
                }

                highlight: highlightBar
                highlightFollowsCurrentItem: true
                focus: true

//                header: Component {}
            }
        }
    }

    Component {
        id: highlightBar
        Rectangle {
            width: listView.currentItem !== null ? listView.currentItem.width : implicitWidth
            height: listView.currentItem !== null ? listView.currentItem.height : implicitHeight
            color: Material.color(Material.Teal)
        }
    }

    function startPositioning() {
        positionMethodText.text = printableMethod(Positioning.supportedPositioningMethods);

        if (Positioning.supportedPositioningMethods === Positioning.NoPositioningMethods ||
            Positioning.supportedPositioningMethods === Positioning.NonSatellitePositioningMethods) {

            console.log("No real positioning methods, using NMEA file")
            Positioning.nmeaSource = "SpecialDelivery2.nmea"
            positionMethodText.text = printableMethod(Positioning.supportedPositioningMethods) + " [" + Positioning.nmeaSource + "]"
        }

        if (!Positioning.active) {
            positionSource.start()
        }
        positionSource.update()
    }

    Component.onCompleted: {
        DBJS.dbInit();
        startPositioning();
    }
}

/*##^##
Designer {
    D{i:0;height:1500;width:800}
}
##^##*/
