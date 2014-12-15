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

    onHealthPointsChanged: {
        if(healthPoints < 0) {
            healthPoints = 0
            spawnTimer.stop()
        }
    }

    Item {
        anchors.centerIn: parent
        width: parent.width * 0.9
        height: parent.height * 0.9
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
            width: parent.width * 0.8
            height: parent.height * 0.8
            color: team.lightColor
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
