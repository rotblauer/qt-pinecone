
import QtQuick 2.10
import QtQuick.LocalStorage 2.10
import "Database.js" as DBJS

ListModel {
    id: listModel
    Component.onCompleted: DBJS.dbReadAllToListModel('desc', 20)
}
