import QtQuick 2.0

import ".."
import "../movement"
import "../defaults.js" as Defaults

BaseWalker {
    property string type: "raise"
    signal collectedEnergy(var amount)

    objectName: "RandomWalker"
    filename: "walkers/RandomWalker.qml"

    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    informationText: "Random walker."

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
        var randomIndex = parseInt(Math.random() * directions.length);
        var found = false;
        var result = moveResult(randomIndex);
        if(moveAcceptable(randomIndex) && percolationSystem.team(result.row, result.column) === team.teamId) {
            moveStrategy = randomIndex;
            strategy = "move";
        } else {
            strategy = "construct";
        }
    }
}
