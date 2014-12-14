import QtQuick 2.0
import org.dragly.perc 1.0

import ".."

Item {
    signal move(var currentTime)
    property EntityBase owner: parent
    property var percolationSystem: parent.percolationSystem
    property var occupationGrid: parent.occupationGrid
    property var oldOwner: null

    function moveIfAvailable(row, col) {
        var previousRow = parent.row
        var previousCol = parent.col
        if(percolationSystem.movementCost(row, col) < 1) {
            return false
        }
        if(occupationGrid.isOccupied(row, col)) {
            return false
        }
        occupationGrid.unOccupy(previousRow, previousCol)
        parent.row = row
        parent.col = col
        occupationGrid.occupy(row, col)
        return true
    }

    onParentChanged: {
        parent.move.connect(move)
        if(oldOwner) {
            oldOwner.move.disconnect()
        }
        oldOwner = parent
    }
}
