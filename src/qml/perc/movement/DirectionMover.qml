import QtQuick 2.0

Mover {
    id: moverRoot
    property string directionName: "left"
    property int direction: 0

    onDirectionChanged: {
        if(directionName !== "left" && directionName !== "right") {
            console.log("ERROR! Type of DirectionMover must be left/right. Type was " + type)
            directionName = "left"
        }
    }

    onMove: {
        if(!parent) {
            return
        }

        var found = false
        var directions = []
        directions[0] = [1,0]
        directions[1] = [0,1]
        directions[2] = [-1,0]
        directions[3] = [0,-1]
        for(var attempt = 0; attempt < 4 && !found; attempt++) {
            var nextSiteRow = parent.row + directions[direction][0]
            var nextSiteCol = parent.col + directions[direction][1]
            if(percolationSystem.isOccupied(nextSiteRow, nextSiteCol)) {
                parent.row = nextSiteRow;
                parent.col = nextSiteCol;
                found = true
                if(directionName === "right") {
                    direction -= 1
                } else {
                    direction += 1
                }
            } else {
                if(directionName === "right") {
                    direction += 1
                } else {
                    direction -= 1
                }
            }
            direction = (direction + 4) % 4
        }
    }
}
