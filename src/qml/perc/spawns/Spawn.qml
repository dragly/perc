import QtQuick 2.0
import QtQuick.Controls 1.4

import ".."
import "../defaults.js" as Defaults

EntityBase {
    id: spawnRoot
    objectName: "Spawn"
    filename: "spawns/Spawn.qml"

    property bool spawn: true
    property bool spawned: false
    property real previousSpawnTime
    property real spawnInterval: 250
    property url spawnType: spawnModes[spawnMode][1]
    property int spawnMode: 0
    property int ticksSinceSpawn: spawnInterval
    readonly property int ticksUntilSpawn: spawnInterval - ticksSinceSpawn

    property var spawnModes: [
        ["Target walker", "../walkers/TargetWalker.qml"],
        ["Random walker", "../walkers/RandomWalker.qml"],
    ]

    property double _colorValue: Math.max(0, Math.min(100, healthPoints)) / 100

    informationText: "Spawn. " + ticksUntilSpawn + " ticks until spawn."

    controls: Component {
        Item {
            Button {
                text: "Spawn type: " + spawnModes[spawnMode][0]
                onClicked: {
                    var nextMode = spawnMode + 1;
                    if(nextMode > spawnModes.length) {
                        nextMode = 0;
                    }
                    spawnMode = nextMode;
                }
            }
        }
    }

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

    onAdvance: {
        if(ticksSinceSpawn > spawnInterval) {
            spawned = true;
            ticksSinceSpawn = 0;
        }
        ticksSinceSpawn += 1;
    }
}
