import QtQuick 2.0
import ".."
import "../defaults.js" as Defaults

EntityBase {
    id: spawnRoot
    objectName: "Spawn"
    signal spawnedWalker(var spawn, var properties)

    property double healthPoints: 100.0

    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    onHealthPointsChanged: {
        if(healthPoints < 0) {
            spawnTimer.stop()
        }
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width * 1.2
        height: parent.height * 1.2
        color: Qt.rgba(team.color.r * 0.8,
                       team.color.g * 0.8,
                       team.color.b * 0.8)
    }

    Timer {
        id: spawnTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            spawnedWalker(spawnRoot, {})
        }
    }
}
