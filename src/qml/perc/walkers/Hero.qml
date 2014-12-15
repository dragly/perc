import QtQuick 2.0
import ".."
import "../movement"
import "../defaults.js" as Defaults

EntityBase {
    id: soldierRoot
    objectName: "Hero"
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
        ignoreOccupation: true
        heuristicScale: 10.0
    }

    Item {
        anchors.centerIn: parent
        width: Defaults.GRID_SIZE * 0.6
        height: Defaults.GRID_SIZE * 0.6

        Rectangle {
            anchors.fill: parent
            radius: parent.width * 0.2
            color: "blue"
        }

        Rectangle {
            anchors.fill: parent
            radius: parent.width * 0.2
            color: "#00000000"
            border.color: team.color
            border.width: parent.width * 0.15
        }

        Rectangle {
            anchors {
                left: parent.left
                top: parent.top
                margins: 15.0
            }
            width: parent.width * 0.2
            height: width
            radius: width / 2

            opacity: 1.0 - _colorValue
            color: "#e31a1c"
        }
    }
}
