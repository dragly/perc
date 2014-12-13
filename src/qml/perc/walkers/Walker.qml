import QtQuick 2.0

import ".."
import "../defaults.js" as Defaults

EntityBase {
    objectName: "Walker"
    property alias color: rect.color

    Component.onCompleted: {
        if(team === null) {
            throw "Walker created without a team"
        }
    }

    smooth: true

    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    Rectangle {
        id: rect
        color: team.color
        anchors.centerIn: parent

        width: Defaults.GRID_SIZE * 0.7
        height: Defaults.GRID_SIZE * 0.7
    }
}
