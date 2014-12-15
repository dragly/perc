import QtQuick 2.0
import org.dragly.perc 1.0
import ".."

Mover {
    id: aStarMoverRoot
    property var pathX: []
    property var pathY: []
    property var grid: []
    property EntityBase target: null
    property bool pathDirty: true

    function resetPath() {
        if(!percolationSystem) {
            return
        }
        if(!target) {
            return
        }
        if(target.row === parent.row && target.col === parent.col) {
            return
        }
        astar.clear()
        var currentTime = Date.now()
        astar.findPath(Qt.point(parent.row, parent.col), Qt.point(target.row, target.col))
        var finalTime = Date.now()
        var difference = finalTime - currentTime
        console.log("Found path in " + difference + " ms")
        pathDirty = false
    }

    Connections {
        target: aStarMoverRoot.target
        onRowChanged: {
            pathDirty = true
        }
        onColChanged: {
            pathDirty = true
        }
    }

    onTargetChanged: {
        pathDirty = true
    }

    onMove: {
        if(astar.isEmpty() || pathDirty) {
            resetPath();
        }
        var next = astar.next()
        if(moveIfAvailable(next.x, next.y)) {
            astar.pop()
        }
    }

    AStar {
        id: astar
        percolationSystem: parent.percolationSystem
    }
}
