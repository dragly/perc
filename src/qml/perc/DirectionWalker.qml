import QtQuick 2.0

Walker {
    property string type: "left"
    property int direction: 0
    color: (type === "left" ? "red" : "orange")
    onTypeChanged: {
        if(type !== "left" && type !== "right") {
            console.log("ERROR! Type of walker must be left/right.")
            direction = "left"
        }
    }

    function move() {
        var found = false
        var directions = []
        directions[0] = [1,0]
        directions[1] = [0,1]
        directions[2] = [-1,0]
        directions[3] = [0,-1]
        for(var attempt = 0; attempt < 4 && !found; attempt++) {
            var nextSiteRow = row + directions[direction][0]
            var nextSiteCol = col + directions[direction][1]
            if(percolationSystem.isOccupied(nextSiteRow, nextSiteCol)) {
                row = nextSiteRow;
                col = nextSiteCol;
                found = true
                if(type === "right") {
                    direction -= 1
                } else {
                    direction += 1
                }
            } else {
                if(type === "right") {
                    direction += 1
                } else {
                    direction -= 1
                }
            }
            direction = (direction + 4) % 4
        }
    }
}
