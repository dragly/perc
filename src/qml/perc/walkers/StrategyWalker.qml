import QtQuick 2.0

import ".."
import "../movement"
import "../defaults.js" as Defaults

EntityBase {
    filename: "walkers/StrategyWalker.qml"

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
