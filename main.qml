import QtQuick 2.10			//Item
import QtQuick.LocalStorage 2.10
import QtPositioning 5.13   //Positioning
import QtQuick.Controls 2.1	//Dialog
import QtQuick.Layouts 1.11
import QtQuick.Window 2.2
import "Database.js" as DBJS

Item {
	id: window
    visible: true
    width: Screen.width
    height: Screen.height

	function api_post(callback, end_point, send_data, params) {
        var xhr = new XMLHttpRequest();
        params = params || {};

        var parameters = "";
        for (var p in params) {
            parameters += "&" + p + "=" + params[p];
        }
        var request = end_point + "?" + parameters;
        console.log(request)
        send_data = JSON.stringify(send_data)
        console.log(send_data)

        xhr.onreadystatechange = function() {processRequest(xhr, callback);};

        xhr.open('POST', request, true);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("Accept", "application/json");
        xhr.send(send_data);
    }

    function api_get(callback, end_point, params) {
        var xhr = new XMLHttpRequest();
        params = params || {};

        var parameters = "";
        for (var p in params) {
            parameters += "&" + p + "=" + params[p];
        }
        var request = end_point + "?" + parameters;
        console.log(request)

        xhr.onreadystatechange = function() {processRequest(xhr, callback);};

        xhr.open('GET', request, true);
        xhr.setRequestHeader("Content-Type", "application/json");
        xhr.setRequestHeader("Accept", "application/json");
        xhr.send('');
    }

    function processRequest(xhr, callback, e) {
        if (xhr.readyState === 4) {
            console.log(xhr.status)
            var response
            try {
                response = JSON.parse(xhr.responseText);
            } catch (e) {
                response = xhr.responseText
            }
            callback(xhr.status, response);
        }
    }

    PositionSource {
        id: positionSource
//        updateInterval: 1000

//        active: true
        onPositionChanged: {
            console.log("(onPositionChanged) position", positionSource.position);
//            var coord = positionSource.position.coordinate;
//            positionText.text = coord.longitude + ", " + coord.latitude;

            console.log("positionSource.nmeaSource", positionSource.nmeaSource)
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
            return "Satellite";
        else if (method === PositionSource.NoPositioningMethods)
            return "Not available"
        else if (method === PositionSource.NonSatellitePositioningMethods)
            return "Non-satellite"
        else if (method === PositionSource.AllPositioningMethods)
            return "Multiple"
        return "source error";
    }

    ColumnLayout {
        anchors.fill: parent
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
//        Row {
//            Text {
//                id: mytext
//                text: "hello world"
//            }
//        }
        RowLayout {
//            Button {
//                text: "and click me!"
//                onClicked: {
////                    dialog.open()
//                    mytext.text = inputstuff.text
//                }
//            }
            Button {
                id: locateButton
                text: "Locate & update"
                onClicked: {
                    positionSource.start()
                    if (positionSource.supportedPositioningMethods === PositionSource.NoPositioningMethods) {
//                    if (positionSource.supportedPositioningMethods === PositionSource.NonSatellitePositioningMethods) {
                        console.log("No positioning methods");
                        positionSource.nmeaSource = "output.nmea";
                        positionMethodText.text = "(nmea filesource): " + printableMethod(positionSource.supportedPositioningMethods);
                    }
                    if (positionSource.supportedPositioningMethods === PositionSource.NonSatellitePositioningMethods) {
                        console.log("Non-satellite positioning methods");
                        positionSource.nmeaSource = "output.nmea";
                        positionMethodText.text = "(nmea filesource): " + printableMethod(positionSource.supportedPositioningMethods);
                    }
                    positionMethodText.text = printableMethod(positionSource.supportedPositioningMethods);
                    positionSource.update();
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
                        }, "https://icanhazip.com/v4", {});
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

                function insertrec() {
                    var rowid = parseInt(DBJS.dbInsert("any_date", inputstuff.text, 42), 10)
                    if (rowid) {
                        listView.model.setProperty(listView.currentIndex, "id", rowid)
                        listView.forceLayout()
                    }
                    return rowid;
                }

                function initrec_new() {

                    inputstuff.clear()

                    listView.model.insert(0, {
                                              date: "",
                                              trip_desc: "",
                                              distance: 0
                                          })
                    listView.currentIndex = 0
                }

                function setlistview() {
                    listView.model.setProperty(listView.currentIndex, "date",
                                               "any_date")
                    listView.model.setProperty(listView.currentIndex, "trip_desc",
                                               inputstuff.text)
                    listView.model.setProperty(listView.currentIndex, "distance",
                                               42)
                }

                onClicked: {
                    console.log("Thinking about saving: ", inputstuff.text);
                    var rowid = insertrec();
                    if (rowid) {
                        console.log("OK saved, row id:", rowid);
                        setlistview();
                        initrec();
                        listView.forceLayout();
                    }

                }
            }
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
    ListView {
        id: listView
        Layout.fillWidth: true
        Layout.fillHeight: true
        model: MyModel {}
        delegate: MyDelegate {
//            onClicked: listView.currentIndex = index
        }
//        // Don't allow changing the currentIndex while the user is creating/editing values.
//        enabled: !window.creatingNewEntry && !window.editingEntry

        highlight: highlightBar
        highlightFollowsCurrentItem: true
        focus: true

        header: Component {
            Text {
                text: "Saved activities"
            }
        }
    }
    Text {
        id: statusText

        color: "red"
//                Layout.fillWidth: true
        font.bold: true
        font.pointSize: 20

        text: "status here"
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

//        Item {
//            width: 200
//            height: 200
//
//            Rectangle {
//                x: 50
//                y: 50
//                width: 100
//                height: 100
//                color: "green"
//             }
//
//             Rectangle {
//                x: 100
//                y: 100
//                width: 50
//                height: 50
//                color: "yellow"
//             }
//        }


//	Column {
//		anchors.centerIn: parent
//
//		TextField {
//			id: inputstuff
//
//			anchors.horizontalCenter: parent.horizontalCenter
//			placeholderText: "Write something ..."
//		}
//
//		Button {
//			anchors.horizontalCenter: parent.horizontalCenter
//			text: "and click me!"
//			onClicked: dialog.open()
//		}
//	}
//
//	Dialog {
//		id: dialog
//
//		x: (window.width - width) * 0.5
//		y: (window.height - height) * 0.5
//
//		contentWidth: window.width * 0.5
//		contentHeight: window.height * 0.25
//		standardButtons: Dialog.Ok
//
//		contentItem: Label {
//			text: inputstuff.text
//		}


