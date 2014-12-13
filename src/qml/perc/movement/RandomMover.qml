import QtQuick 2.0

Mover {
    id: moverRoot

    onMove: {
        if(!owner) {
            return
        }

        var randomIndex = parseInt(Math.random() * 4)
        var found = false
        var directions = []
        directions[0] = [1,0]
        directions[1] = [-1,0]
        directions[2] = [0,1]
        directions[3] = [0,-1]
        for(var attempt = 0; attempt < 4 && !found; attempt++) {
            var nextSiteRow = parent.row + directions[randomIndex][0]
            var nextSiteCol = parent.col + directions[randomIndex][1]
            if(percolationSystem.isOccupied(nextSiteRow, nextSiteCol)) {
                parent.row = nextSiteRow;
                parent.col = nextSiteCol;
                found = true
            } else {
                randomIndex += 1
                randomIndex = (randomIndex + 4) % 4
            }
        }
    }
}
