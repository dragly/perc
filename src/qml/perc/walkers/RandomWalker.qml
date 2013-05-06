import QtQuick 2.0

Walker {
    property string type: "raise"

    onTypeChanged: {
        if(type !== "raise" && type !== "lower") {
            console.log("Type must be raise or lower")
            type = "raise"
        }
    }

    color: (type === "raise") ? "yellow" : "pink"
    function move() {
        var randomIndex = parseInt(Math.random() * 4)
        var found = false
        var directions = []
        directions[0] = [1,0]
        directions[1] = [-1,0]
        directions[2] = [0,1]
        directions[3] = [0,-1]
        for(var attempt = 0; attempt < 4 && !found; attempt++) {
            var nextSiteRow = row + directions[randomIndex][0]
            var nextSiteCol = col + directions[randomIndex][1]
            if(percolationSystem.isOccupied(nextSiteRow, nextSiteCol)) {
                row = nextSiteRow;
                col = nextSiteCol;
                found = true
                if(type === "raise") {
                    percolationSystem.raiseValue(nextSiteRow,nextSiteCol)
                } else {
                    percolationSystem.lowerValue(nextSiteRow + directions[randomIndex][0], nextSiteCol + directions[randomIndex][1])
                }
            } else {
                randomIndex += 1
                randomIndex = (randomIndex + 4) % 4
            }
        }
    }
}