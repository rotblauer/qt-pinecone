import QtQuick 2.10

import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12

import QtPositioning 5.13
import QtQuick.LocalStorage 2.10

import QtQuick.Layouts 1.11
import QtQuick.Window 2.2

import "Database.js" as DBJS
import Qt.labs.settings 1.0


ApplicationWindow {
    id: window
    visible: true
    width: 400 // Screen.width
    height: 800 // Screen.height

    Material.theme: Material.Dark
    Material.accent: Material.Purple

    Settings {
        property alias x: window.x
        property alias y: window.y
        property alias width: window.width
        property alias height: window.height
    }

    function api_post(callback, end_point, send_data, params) {
        var xhr = new XMLHttpRequest()
        params = params || {}

        var parameters = ""
        for (var p in params) {
            parameters += "&" + p + "=" + params[p]
        }
        var request = end_point + "?" + parameters
        console.log(request)
        send_data = JSON.stringify(send_data)
        console.log(send_data)

        xhr.onreadystatechange = function () {
            processRequest(xhr, callback)
        }

        xhr.open('POST', request, true)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.setRequestHeader("Accept", "application/json")
        xhr.send(send_data)
    }

    function api_get(callback, end_point, params) {
        var xhr = new XMLHttpRequest()
        params = params || {}

        var parameters = ""
        for (var p in params) {
            parameters += "&" + p + "=" + params[p]
        }
        var request = end_point + "?" + parameters
        console.log(request)

        xhr.onreadystatechange = function () {
            processRequest(xhr, callback)
        }

        xhr.open('GET', request, true)
        xhr.setRequestHeader("Content-Type", "application/json")
        xhr.setRequestHeader("Accept", "application/json")
        xhr.send('')
    }

    function processRequest(xhr, callback, e) {
        if (xhr.readyState === 4) {
            console.log(xhr.status);
            var response;
            try {
                response = JSON.parse(xhr.responseText);
            } catch (ee) {
                response = xhr.responseText;
            }
            callback(xhr.status, response);
        } else if (e) {
            console.log("request error:", e);
        }
    }

    function getDBRowsCount() {
        var count = DBJS.dbCount();
        return count;
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
                              longitude: withPrec(position.coordinate.longitude, precLL),
                              latitude: withPrec(position.coordinate.latitude, precLL),
                              altitude: withPrec(position.coordinate.altitude, precVel) || 0,
                              direction: withPrec(position.direction, precVel) || -1,
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
                listView.model.remove(30, listView.model.count - 31);
            }

            listView.currentIndex = 0;
            listView.forceLayout()

            var count = getDBRowsCount();
            console.log("db contains", count, "");
            entriesCount.text = "Q: " + count;
        }
        return rowid;
    }
    function logPosition(position) {
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
        active: true
        // nmeaSource: "SpecialDelivery2.nmea"
        onPositionChanged: {
            console.log("-> positionSource.nmeaSource", positionSource.nmeaSource)
            console.log("positionSource.method", printableMethod(positionSource.supportedPositioningMethods))

            var stat = "info";
            var statT = "GPS: OK";

            if (positionSource.position && positionSource.position.coordinate.isValid) {
                var savedRowId = saveValidPosition(positionSource.position);
                if (savedRowId > 1) {
//                    logPosition(positionSource.position);
                } else {
                    statT = "DB: save failed";
                    stat = "error"
                }
            } else {
                statT = "GPS: invalid position";
                stat = "error"
            }
            setStatusDisplay(stat, statT);
        }

        onSourceErrorChanged: {
            if (sourceError == PositionSource.NoError)
                return
            setStatusDisplay("error", sourceError)
            stop()
        }
        onUpdateTimeout: {
            setStatusDisplay("warn", "update timed out");
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
        if (positionSource.supportedPositioningMethods
                === PositionSource.NoPositioningMethods ||
            positionSource.supportedPositioningMethods
                            === PositionSource.NonSatellitePositioningMethods) {
            console.log("No real positioning methods, using NMEA file")
            positionSource.nmeaSource = "SpecialDelivery2.nmea"
            positionMethodText.text = "(nmea filesource): " + printableMethod(
                        positionSource.supportedPositioningMethods)
        }

        if (!positionSource.active) {
            positionSource.start()
        }
        positionSource.update()
    }

    function setStatusDisplay(qualitative, text) {
        console.log(qualitative + ": " + text);
        statusText.font.bold = false
        switch (qualitative) {
        case "info":
            statusText.color = Material.color(Material.Teal)
            break;
        case "warn":
            statusText.color = Material.color(Material.Orange)
            break;
        case "error":
            statusText.color = Material.color(Material.Red)
            statusText.font.bold = true
            break;
        }
        statusText.text = text;
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.rightMargin: 0
        anchors.bottomMargin: 0
        anchors.leftMargin: 0
        anchors.topMargin: 0
        GridLayout {
            Layout.fillWidth: true
            columns: 3
            Text {
                id: positionMethodText
                text: "<POSITIONING METHOD>"
                color: Material.color(Material.Teal)
                Layout.fillWidth: true
            }
            Text {
                id: entriesCount
                text: "<NUMENTRIES>"
                color: Material.color(Material.Teal)
                Layout.fillWidth: true
            }
            Text {
                id: statusText
                text: "<STATUS>"
                color: Material.color(Material.Grey)
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignRight
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
