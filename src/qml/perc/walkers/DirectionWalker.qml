import QtQuick 2.0

import ".."
import "../movement"
import "../defaults.js" as Defaults

EntityBase {
    objectName: "DirectionWalker"
    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    DirectionMover {
        id: mover
    }

    Rectangle {
        id: rect
        width: Defaults.GRID_SIZE * 0.6
        height: width
        radius: width / 2
        color: "transparent"

        border.color: team.color
        border.width: parent.width * 0.1
        anchors.centerIn: parent
    }
}
