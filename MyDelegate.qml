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
                Layout.preferredWidth: parent.width / 6
            }
            Text {
                id: r_longitude
                text: delegate.longitude
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 5
            }
            Text {
                id: r_latitude
                text: delegate.latitude
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 5
            }
            Text {
                id: r_altitude
                text: delegate.altitude != 0 ? delegate.altitude : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 9 * 2
            }
            Text {
                id: r_direction
                text: delegate.direction != -1 ? delegate.direction : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 9 * 2
            }
            Text {
                id: r_horizontal_accuracy
                text: delegate.horizontal_accuracy != -1 ? delegate.horizontal_accuracy : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 9 * 2
            }
            Text {
                id: r_vertical_accuracy
                text: delegate.vertical_accuracy != -1 ? delegate.vertical_accuracy : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 9 * 2
            }
            Text {
                id: r_speed
                text: delegate.speed != -1 ? delegate.speed : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 9 *2
            }
            Text {
                id: r_vertical_speed
                text: delegate.vertical_speed != -1 ? delegate.vertical_speed : "_"
//                Layout.fillWidth: true
                Layout.preferredWidth: parent.width / 9 * 2
            }
        }
    }
}
