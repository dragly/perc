import QtQuick 2.0
import ".."

Mover {
    id: moverRoot
    property string directionName: "left"
    property int direction: 0
    property EntityBase target: null

    onDirectionChanged: {
        if(directionName !== "left" && directionName !== "right") {
            console.log("ERROR! Type of DirectionMover must be left/right. Type was " + type)
            directionName = "left"
        }
    }

    onMove: {
        if(!parent || !target) {
            return
        }

        var diffRow = target.row - parent.row
        var diffCol = target.col - parent.col

        var moved = false
        if(diffRow > 0) {
            moved = moveIfAvailable(parent.row + 1, parent.col)
        }
        if(!moved && diffRow < 0) {
            moved = moveIfAvailable(parent.row - 1, parent.col)
        }
        if(!moved && diffCol > 0) {
            moved = moveIfAvailable(parent.row, parent.col + 1)
        }
        if(!moved && diffCol < 0) {
            moved = moveIfAvailable(parent.row, parent.col - 1)
        }
    }
}
