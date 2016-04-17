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
        var randomIndex = parseInt(Math.random() * directions.length);
        var found = false;
        for(var attempt = 0; attempt < 4 && !found; attempt++) {
            var result = moveResult(randomIndex);
            if(moveAcceptable(randomIndex) && percolationSystem.team(result.row, result.column) === team.teamId) {
                moveStrategy = randomIndex;
                found = true;
            } else {
                randomIndex += 1;
                randomIndex = (randomIndex + 4) % 4;
            }
        }
        strategy = "move";
    }
}
