
import QtQuick 2.10
import QtQuick.LocalStorage 2.10
import QtQuick.Layouts 1.11

Item {
    id: delegate

    width: listView.width
//    Layout.fillWidth: true
    height: 18

    required property int index

    required property string timestamp
    required property real longitude
    required property real latitude
    required property real altitude
    required property real direction
    required property real horizontal_accuracy
    required property real vertical_accuracy
    required property real speed
    required property real vertical_speed

    signal clicked()

    function formatDate(datestring) {
        var str = new Date(datestring).toISOString();
        return str.substring(str.indexOf("T") + 1, str.indexOf("Z") - 4);
    }
    Rectangle {
        id: baseRec
        anchors.fill: parent
        opacity: 0.8
        color: delegate.index % 2 ? "lightgrey" : "grey"

        MouseArea {
            anchors.fill: parent
            onClicked: delegate.clicked()
        }
        GridLayout {
            anchors.fill:parent
            columns: 9

            Text {
                id: r_timestamp
                text: formatDate(delegate.timestamp)
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 8
            }
            Text {
                id: r_longitude
                text: delegate.longitude
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 7
            }
            Text {
                id: r_latitude
                text: delegate.latitude
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 7
            }
            Text {
                id: r_altitude
                text: delegate.altitude != 0 ? delegate.altitude : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 10
            }
            Text {
                id: r_direction
                text: delegate.direction != -1 ? delegate.direction : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 10
            }
            Text {
                id: r_horizontal_accuracy
                text: delegate.horizontal_accuracy != -1 ? delegate.horizontal_accuracy : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 10
            }
            Text {
                id: r_vertical_accuracy
                text: delegate.vertical_accuracy != -1 ? delegate.vertical_accuracy : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 10
            }
            Text {
                id: r_speed
                text: delegate.speed != -1 ? delegate.speed : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 10
            }
            Text {
                id: r_vertical_speed
                text: delegate.vertical_speed != -1 ? delegate.vertical_speed : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 10
            }
        }
    }
}
