import QtQuick 2.0
import QtQuick.Controls 1.4

import ".."
import "../defaults.js" as Defaults

BaseEntity {
    id: spawnRoot
    objectName: "Spawn"
    filename: "spawns/Spawn.qml"

    property bool spawn: true
    property bool spawned: false
    property real previousSpawnTime
    property real spawnInterval: 100
    property url spawnType: "../walkers/TargetWalker.qml"

    property int ticksSinceSpawn: spawnInterval
    readonly property int ticksUntilSpawn: spawnInterval - ticksSinceSpawn

    informationText: "Spawn. " + ticksUntilSpawn + " ticks until spawn."

    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    onHealthPointsChanged: {
        if(healthPoints < 0) {
            healthPoints = 0
        }
    }

    Item {
        anchors.centerIn: parent
        width: parent.width * 1.2
        height: parent.height * 1.2

        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.8
            height: parent.height * 0.8
            color: Qt.lighter(team.color, 1.5)
            border.width: width * 0.1
            border.color: Qt.darker(team.color, 1.5)
        }
    }

    onAdvance: {
        if(ticksSinceSpawn > spawnInterval) {
            spawned = true;
            ticksSinceSpawn = 0;
        }
        ticksSinceSpawn += 1;
    }
}
