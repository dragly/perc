import QtQuick 2.0
import ".."
import "../defaults.js" as Defaults

EntityBase {
    id: spawnRoot
    objectName: "Spawn"
    signal spawnedWalker(var spawn, var properties)

    property alias interval: spawnTimer.interval
    property double healthPoints: 100.0

    property double _colorValue: Math.max(0, Math.min(100, healthPoints)) / 100

    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    occupying: false

    onHealthPointsChanged: {
        if(healthPoints < 0) {
            healthPoints = 0
            spawnTimer.stop()
        }
    }

    Item {
        anchors.centerIn: parent
        width: parent.width * 0.7
        height: parent.height * 0.7

        Rectangle {
            anchors.fill: parent
            radius: parent.width * 0.2
            color: team.lightColor
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

    Timer {
        id: spawnTimer
        interval: 1000
        triggeredOnStart: true
        repeat: true
        running: true
        onTriggered: {
            spawnedWalker(spawnRoot, {})
            interval = 600 + Math.random() * 2000
        }
    }
}
