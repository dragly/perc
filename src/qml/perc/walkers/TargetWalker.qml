import QtQuick 2.0

import ".."

Walker {
    property EntityBase target: null

    function move(currentTime) {
        var found = false
        var directions = []
        var deltaX = col - target.col
        var deltaY = row - target.row
        if(Math.abs(deltaX) > Math.abs(deltaY)) {
            if(deltaX > 0) {
                directions[0] = [ 1, 0]
                directions[1] = [-1, 0]
                directions[2] = [ 0, 1]
                directions[3] = [ 0,-1]
            } else {
                directions[0] = [-1, 0]
                directions[1] = [ 1, 0]
                directions[2] = [ 0, 1]
                directions[3] = [ 0,-1]
            }
        } else {
            if(deltaY > 0) {
                directions[0] = [ 0, 1]
                directions[1] = [ 0,-1]
                directions[2] = [ 1, 0]
                directions[3] = [-1, 0]
            } else {
                directions[0] = [ 0,-1]
                directions[1] = [ 0, 1]
                directions[2] = [ 1, 0]
                directions[3] = [-1, 0]
            }
        }

        var direction = 0
        for(var attempt = 0; attempt < 4 && !found; attempt++) {
            var nextSiteRow = row + directions[direction][0]
            var nextSiteCol = col + directions[direction][1]
            if(percolationSystem.isOccupied(nextSiteRow, nextSiteCol)) {
                row = nextSiteRow;
                col = nextSiteCol;
                found = true
            } else {
                direction += 1
            }
            direction = (direction + 4) % 4
        }
    }

    informationText: "Target walker " + (team ? "\nteam: " + team.name : "")
}
