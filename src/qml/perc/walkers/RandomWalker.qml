import QtQuick 2.0

import "../movement"

Walker {
    objectName: "RandomWalker"
    property string type: "raise"
    signal collectedEnergy(var amount)

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
}
