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

    PositionSource {
        id: positionSource
        updateInterval: 1000
        //      active: true
        // nmeaSource: "SpecialDelivery2.nmea"
        onPositionChanged: {
            console.log("positionSource.nmeaSource", positionSource.nmeaSource)
//            console.log("(onPositionChanged) position", positionSource.position)
            console.log("position.coordinate.latitude", positionSource.position.coordinate.latitude)
            console.log("position.coordinate.longitude", positionSource.position.coordinate.longitude)
            console.log("position.coordinate.altitude", positionSource.position.coordinate.altitude)
            console.log("position.coordinate.isValid", positionSource.position.coordinate.isValid)
            console.log("position.altitudeValid", positionSource.position.altitudeValid)
            console.log("position.direction", positionSource.position.direction)
            console.log("position.directionValid", positionSource.position.directionValid)
            console.log("position.horizontalAccuracy", positionSource.position.horizontalAccuracy)
            console.log("position.horizontalAccuracyValid", positionSource.position.horizontalAccuracyValid)
            console.log("position.latitudeValid", positionSource.position.latitudeValid)
            console.log("position.longitudeValid", positionSource.position.longitudeValid)
            console.log("position.magneticVariation", positionSource.position.magneticVariation)
            console.log("position.magneticVariationValid", positionSource.position.magneticVariationValid)
            console.log("position.speed", positionSource.position.speed)
            console.log("position.speedValid", positionSource.position.speedValid)
            console.log("position.timestamp", positionSource.position.timestamp)
            console.log("position.verticalAccuracy", positionSource.position.verticalAccuracy)
            console.log("position.verticalAccuracyValid", positionSource.position.verticalAccuracyValid)
            console.log("position.verticalSpeed", positionSource.position.verticalSpeed)
            console.log("position.verticalSpeedValid", positionSource.position.verticalSpeedValid)
        }

        onSourceErrorChanged: {
            if (sourceError == PositionSource.NoError)
                return

            console.log("Source error: " + sourceError)
            positionText.text = "error: " + sourceError
            stop()
        }
        onUpdateTimeout: {
            positionText.text = "update timed out"
        }
    }
    function printableMethod(method) {
        if (method === PositionSource.SatellitePositioningMethods)
            return "Satellite"
        else if (method === PositionSource.NoPositioningMethods)
            return "Not available"
        else if (method === PositionSource.NonSatellitePositioningMethods)
            return "Non-satellite"
        else if (method === PositionSource.AllPositioningMethods)
            return "Multiple"
        return "source error"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.rightMargin: 0
        anchors.bottomMargin: 0
        anchors.leftMargin: 0
        anchors.topMargin: 0
        RowLayout {
            Text {
                id: positionText
                text: "position text"
            }
        }
        RowLayout {
            Text {
                id: positionMethodText
                text: "position method text"
            }
        }
        RowLayout {
            Button {
                id: locateButton
                text: "Locate & update"
                onClicked: {
                    if (positionSource.supportedPositioningMethods
                            === PositionSource.NoPositioningMethods) {
                        console.log("No positioning methods")
                        positionSource.nmeaSource = "SpecialDelivery2.nmea"
                        positionMethodText.text = "(nmea filesource): " + printableMethod(
                                    positionSource.supportedPositioningMethods)
                    }
                    if (positionSource.supportedPositioningMethods
                            === PositionSource.NonSatellitePositioningMethods) {
                        console.log("Non-satellite positioning methods")
                        positionSource.nmeaSource = "SpecialDelivery2.nmea"
                        positionMethodText.text = "(nmea filesource): " + printableMethod(
                                    positionSource.supportedPositioningMethods)
                    }
                    positionSource.nmeaSource = "SpecialDelivery2.nmea"
                    if (!positionSource.active) {
                        positionSource.start()
                    }
                    positionSource.update()
                }
            }
        }
        RowLayout {
            GridLayout {
                id: mygrid

                columns: 2

                Button {
                    id: jsonReqButton
                    text: "Get IP"
                    onClicked: {
                        api_get(function (status, body) {
                            if (status === 200) {
                                textIP.text = body
                            }
                        }, "https://icanhazip.com/v4", {})
                    }
                }
                Text {
                    id: textIP
                    text: "position method text"
                }
            }
        }

        RowLayout {
            id: myrowlayout
            TextField {
                id: inputstuff
                Material.accent: Material.Orange
                placeholderText: "Write something ..."
            }
            Button {
                text: "Dialog"
                onClicked: {
                    dialog.open()
                }
            }

            Button {
                id: saveButton
                text: "Save field"

                //                Material.background: Material.Teal
                Material.foreground: Material.Green
                //                highlighted: true
                //                Material.accent: Material.Orange

                function save() {
                    console.log("Thinking about saving: ", inputstuff.text)
                    var rowid = parseInt(DBJS.dbInsert("any_date", inputstuff.text, 42), 10);
                    if (rowid) {
                        // Manually insert a COPY of the record into the listview model.
                        listView.model.insert(0, {
                                                  date: "any_date",
                                                  trip_desc: inputstuff.text,
                                                  distance: 42
                                              })
                        listView.currentIndex = 0;
                        console.log("Save OK", rowid);
                        listView.forceLayout()
                        inputstuff.clear()

                        var count = DBJS.dbCount();
                        console.log("db contains", count, "entries");
                        return;
                    }
                    console.log("Save failed");
                }

                onClicked: {
                    save()
                }
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
                    //                    onClicked: listView.currentIndex = index
                }

                highlight: highlightBar
                highlightFollowsCurrentItem: true
                focus: true

                header: Component {
                    Text {
                        text: "Saved activities"
                    }
                }
            }
        }

        RowLayout {
            id: rowLayout1
            Layout.fillWidth: true
            height: 100

            Pane {
                width: 120
                height: 120
                Layout.fillWidth: true

                Material.elevation: 6

                Label {
                    text: qsTr("I'm a card!")
                    anchors.centerIn: parent
                }
            }

            Text {
                id: statusText

                color: "red"
                Layout.fillWidth: true
                font.bold: true

                text: "status here"
            }

        }

        RowLayout {
            id: rowLayout2
            width: 100
            height: 100
        }

    }

    Component {
        id: highlightBar
        Rectangle {
            width: listView.currentItem !== null ? listView.currentItem.width : implicitWidth
            height: listView.currentItem !== null ? listView.currentItem.height : implicitHeight
            color: "lightgreen"
        }
    }

    Dialog {
        id: dialog

        x: (window.width - width) * 0.5
        y: (window.height - height) * 0.5

        contentWidth: window.width * 0.5
        contentHeight: window.height * 0.25
        standardButtons: Dialog.Ok

        contentItem: Label {
            text: inputstuff.text
        }
    }


    Component.onCompleted: {
        DBJS.dbInit()
    }
}

/*##^##
Designer {
    D{i:0;height:1500;width:800}
}
##^##*/
