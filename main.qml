import QtQuick 2.14

import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

import QtPositioning 5.13
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
    width: 720 // Screen.width
    height: 1440 // Screen.height

    Material.theme: Material.Dark
    Material.accent: Material.Purple

    property int pushBatchSize: 100
    property int pushBatchEvery: 100

    Settings {
        property alias x: window.x
        property alias y: window.y
        property alias width:  window.width
        property alias height:  window.height
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
            if (listView.model.count > 20) {
                listView.model.remove(20, listView.model.count - 20);
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

    function logPosition(position) {
        console.log("-> positionSource.nmeaSource", positionSource.nmeaSource)
        console.log("positionSource.method", printableMethod(positionSource.supportedPositioningMethods))
        console.log("position.timestamp", position.timestamp)
        console.log("position.coordinate.longitude", position.coordinate.longitude)
        console.log("position.coordinate.latitude", position.coordinate.latitude)
        console.log("position.coordinate.altitude", position.coordinate.altitude)
        console.log("position.coordinate.isValid", position.coordinate.isValid)
        console.log("position.altitudeValid", position.altitudeValid)
        console.log("position.direction", position.direction)
        console.log("position.directionValid", position.directionValid)
        console.log("position.horizontalAccuracy", position.horizontalAccuracy)
        console.log("position.horizontalAccuracyValid", position.horizontalAccuracyValid)
        console.log("position.latitudeValid", position.latitudeValid)
        console.log("position.longitudeValid", position.longitudeValid)
        console.log("position.magneticVariation", position.magneticVariation)
        console.log("position.magneticVariationValid", position.magneticVariationValid)
        console.log("position.speed", position.speed)
        console.log("position.speedValid", position.speedValid)
        console.log("position.verticalAccuracy", position.verticalAccuracy)
        console.log("position.verticalAccuracyValid", position.verticalAccuracyValid)
        console.log("position.verticalSpeed", position.verticalSpeed)
        console.log("position.verticalSpeedValid", position.verticalSpeedValid)
    }

    PositionSource {
        id: positionSource
        updateInterval: 1000
        //        active: true
        // nmeaSource: "SpecialDelivery2.nmea"
        onPositionChanged: {
            var stat = "info";
            var statT = "GPS: OK";


            if (positionSource.position && positionSource.position.coordinate.isValid) {

                dashKMH.text = Math.round(position.speed * 3.6)
                dashCoG.text = Math.round(position.direction)
                dashHacc.text = Math.round(position.horizontalAccuracy)

                // Save valid updated position.
                var savedRowId = saveValidPosition(positionSource.position);
                if (savedRowId) {
                    // logPosition(positionSource.position);

                    // Push (all, recursively) to API at simply batched intervals.
                    if (savedRowId % window.pushBatchEvery === 0) {
                        pushBatching(window.pushBatchSize);
                    }

                } else {
                    statT = "DB: save failed";
                    stat = "error"
                }
            } else {
                statT = "GPS: invalid position";
                stat = "error"
            }
            setStatusDisplay(gpsStatusText, stat, statT);
        }

        onSourceErrorChanged: {
            if (sourceError == PositionSource.NoError)
                return
            setStatusDisplay(gpsStatusText, "error", sourceError)
            stop()
        }
        onUpdateTimeout: {
            setStatusDisplay(gpsStatusText, "warn", "update timed out");
        }
    }
    function printableMethod(method) {
        if (method === PositionSource.SatellitePositioningMethods)
            return "sat"
        else if (method === PositionSource.NoPositioningMethods)
            return "na"
        else if (method === PositionSource.NonSatellitePositioningMethods)
            return "nsat"
        else if (method === PositionSource.AllPositioningMethods)
            return "a"
        return "source error"
    }
    function startPositioning() {
        positionMethodText.text = printableMethod(positionSource.supportedPositioningMethods);

        if (positionSource.supportedPositioningMethods === PositionSource.NoPositioningMethods ||
                positionSource.supportedPositioningMethods === PositionSource.NonSatellitePositioningMethods) {

            console.log("No real positioning methods, using NMEA file")
            positionSource.nmeaSource = "SpecialDelivery2.nmea"
            positionMethodText.text = printableMethod(positionSource.supportedPositioningMethods) + " [" + positionSource.nmeaSource + "]"
        }

        if (!positionSource.active) {
            positionSource.start()
        }
        positionSource.update()
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

        Rectangle {
            id: rectangleDash
            width: 200
            height: 150
            anchors.right: parent.right;
            anchors.left: parent.left;
//            color: "#015c40"
            color: parent.color
            Rectangle {
                id: rectangle1
                width: parent.width / 3;
                height: parent.height;
                color: Material.color(Material.Teal)
                Text {
                    id: dashKMHLabel
                    color: "#a1eed1"
                    text: "Km/H"
                    x: rectangle1.x + 10
                    y: rectangle1.y + 10
                }
                Text {
                    id: dashKMH
                    color: "#00ea95"
                    font.pointSize: 54
                    text: "N"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    minimumPointSize: 20
                    minimumPixelSize: 20
                }
            }
            Rectangle {
                id: rectangle2
                x: parent.width / 3;
                width: parent.width / 3;
                height: parent.height;
                color: Material.color(Material.Teal)
                Text {
                    id: dashHeadingLabel
                    color: "#a1eed1"
                    text: "Heading deg"
                    x: 10
                    y: rectangle2.y + 10
                }
                Text {
                    id: dashCoG
                    color: "#00ea95"
                    font.pointSize: 54
                    text: "N"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    minimumPointSize: 20
                    minimumPixelSize: 20
                }
            }
            Rectangle {
                id: rectangle3
                x: parent.width / 3 * 2;
                width: parent.width / 3;
                height: parent.height;
                color: Material.color(Material.Teal)
                Text {
                    id: dashAccuracyLabel
                    color: "#a1eed1"
                    text: "Accuracy meters"
                    x: 10
                    y: rectangle3.y + 10
                }
                Text {
                    id: dashHacc
                    color: "#00ea95"
                    font.pointSize: 54
                    text: "M"
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    minimumPointSize: 20
                    minimumPixelSize: 20
                }
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
            anchors.bottom: parent.bottom;

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

    Component.onCompleted: {
        DBJS.dbInit();
        startPositioning();
        window.height = 1440;
        window.width = 720;
    }
}

/*##^##
Designer {
    D{i:0;height:1500;width:800}
}
##^##*/
