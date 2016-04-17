import QtQuick 2.0

import ".."
import "../movement"
import "../defaults.js" as Defaults

BaseWalker {
    property string directionName: "right"
    property int direction: 0

    filename: "walkers/DirectionWalker.qml"
    objectName: "DirectionWalker"

    onChooseStrategy: {
        console.log("----- Client choosing strategy -----");
        var found = false
        for(var attempt = 0; attempt < 4 && !found; attempt++) {
            if(moveAcceptable(direction)) {
                console.log("Chosen", direction);
                moveStrategy = direction;
                strategy = "move";
                found = true
                if(directionName === "right") {
                    direction -= 1
                } else {
                    direction += 1
                }
            } else {
                console.log("Failed", direction);
                if(directionName === "right") {
                    direction += 1
                } else {
                    direction -= 1
                }
            }
            direction = (direction + 4) % 4
        }
        if(!found) {
            strategy = "none";
        }
        console.log("Chose strategy:", strategy, moveStrategy)
    }
}
