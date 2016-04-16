import QtQuick 2.0

import ".."
import "../movement"
import "../defaults.js" as Defaults

EntityBase {
    objectName: "RandomWalker"
    filename: "walkers/RandomWalker.qml"
    property string type: "raise"
    signal collectedEnergy(var amount)

    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    informationText: "Collector walker " + type + (team ? "\nteam: " + team.name : "")

    onCollectedEnergy: {
        team.addEnergy(amount)
    }

    onTypeChanged: {
        if(type !== "raise" && type !== "lower") {
            console.log("Type must be raise or lower")
            type = "raise"
        }
    }

    RandomMover {
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
