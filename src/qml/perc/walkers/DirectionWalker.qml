import QtQuick 2.0

import ".."
import "../movement"
import "../defaults.js" as Defaults

EntityBase {
//    property alias directon: mover.directonName

    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

//    informationText: "Direction walker " + direction + (team ? "\nteam: " + team.name : "")

    DirectionMover {
        id: mover
    }

    Rectangle {
        id: rect
        color: team.color
        anchors.centerIn: parent

        width: Defaults.GRID_SIZE * 0.7
        height: Defaults.GRID_SIZE * 0.7
    }
}
