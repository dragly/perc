import QtQuick 2.0
import ".."
import "../movement"
import "../defaults.js" as Defaults

EntityBase {
    id: soldierRoot
    objectName: "Soldier"
    property alias target: astar.target
    property real healthPoints: 100.0

    property double _colorValue: Math.max(0, Math.min(100, healthPoints)) / 100

    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    onHealthPointsChanged: {
        if(healthPoints < 0) {
            kill(soldierRoot)
        }
    }

    AStarMover {
        id: astar
    }

    Item {
        anchors.centerIn: parent
        width: Defaults.GRID_SIZE * 0.7
        height: Defaults.GRID_SIZE * 0.7
        Rectangle {
            anchors.fill: parent
            opacity: _colorValue
            color: "#b2df8a"
        }

        Rectangle {
            anchors.fill: parent
            opacity: 1 - _colorValue
            color: "#e31a1c"
        }

        Rectangle {
            anchors.centerIn: parent
            color: team.color
            width: parent.width * 0.6
            height: parent.height * 0.6
        }
    }
}
