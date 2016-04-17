import QtQuick 2.0

import ".."
import "../movement"
import "../defaults.js" as Defaults

BaseWalker {
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

    onChooseStrategy: {
        var randomIndex = parseInt(Math.random() * 4)
        var found = false
        var directions = Defaults.directions;
        for(var attempt = 0; attempt < 4 && !found; attempt++) {
            var nextSiteRow = parent.row + directions[randomIndex][0]
            var nextSiteCol = parent.col + directions[randomIndex][1]
            if(percolationSystem.movementCost(nextSiteRow, nextSiteCol) > 0) {
                strategy = randomIndex;
                found = true
            } else {
                randomIndex += 1
                randomIndex = (randomIndex + 4) % 4
            }
        }
    }

    Rectangle {
        id: rect
        color: team.color
        anchors.centerIn: parent

        width: Defaults.GRID_SIZE * 0.7
        height: Defaults.GRID_SIZE * 0.7
    }
}
