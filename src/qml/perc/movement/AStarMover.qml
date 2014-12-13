import QtQuick 2.0
import ".."

Mover {
    property var path: []
    property var grid: []
    property EntityBase target: null

    onPercolationSystemChanged: {
        // TODO: Do this when number of rows or columns change too
        createGrid()
        resetGrid();
    }

    onMove: {
        if(!target) {
            return
        }
        if(target.row === parent.row && target.col === parent.col) {
            return
        }

        if(path.length === 0) {
            path = findPath(Qt.point(parent.row, parent.col), Qt.point(target.row, target.col))
        }
        var next = path.pop()
        parent.row = next.x
        parent.col = next.y
    }

    function createGrid() {
        var tmp = new Array(percolationSystem.nRows)
        for(var i = 0; i < percolationSystem.nRows; i++) {
            tmp[i] = new Array(percolationSystem.nCols)
        }
        grid = tmp
    }

    function resetGrid() {
        for(var i = 0; i < percolationSystem.nRows; i++) {
            for(var j = 0; j < percolationSystem.nCols; j++) {
                grid[i][j] = {
                    i: i,
                    j: j,
                    G: 0,
                    H: 0,
                    F: 0,
                    cameFrom: null
                }
            }
        }
    }

    function containsSquare(list, square) {
//        for(var i in list) {
//            var otherSquare = list[i]
//            if(square.i === otherSquare.i && square.j === otherSquare.j) {
//                return otherSquare
//            }
//        }
        return (list.indexOf(square) !== -1);
//        return false
    }

    function square(i,j) {
        return {i: i, j: j, G: 0, H: 0, F: 0, cameFrom: null}
    }

    function findPath(startPoint, targetPoint) {
        var startTime = Date.now()
        var endTime = Date.now()
        var diff = endTime - startTime
        var currentTime = Date.now()

        var start = grid[startPoint.x][startPoint.y]
        var target = grid[targetPoint.x][targetPoint.y]
        var current = grid[start.i][start.j]

        var openList = []
        var closedList = []
        openList.push(current)
        closedList.push(current)
        while(openList.length > 0) {
            if(current.i === target.i && current.j === target.j) {
                break
            }
            for(var di = -1; di < 2; di++) {
                for(var dj = -1; dj < 2; dj++) {
                    // Don't include our own site
                    if(di === 0 && dj === 0) {
                        continue
                    }
                    // No diagonal movement
                    if(!(di === 0 || dj === 0)) {
                        continue
                    }

                    var i = current.i + di
                    var j = current.j + dj
                    if(!percolationSystem.inBounds(i,j)) {
                        continue
                    }
                    if(!percolationSystem.isOccupied(i,j)) {
                        continue
                    }
                    var adjacent = grid[i][j]
                    if(containsSquare(closedList, adjacent)) {
                        continue
                    }
                    adjacent.cameFrom = current
                    adjacent.G = current.G + Math.sqrt(di*di + dj*dj)
                    var deltaRow = target.i - adjacent.i
                    var deltaColumn = target.j - adjacent.j
                    adjacent.H = Math.sqrt(deltaRow*deltaRow + deltaColumn*deltaColumn)
                    adjacent.F = adjacent.G + adjacent.H
                    var existingSquare = containsSquare(openList, adjacent)
                    if(containsSquare(openList, adjacent)) {
                        if(adjacent.F < existingSquare.F) {
                            openList.splice(openList.indexOf(existingSquare), 1)
                            openList.push(adjacent)
                        }
                    } else {
                        openList.push(adjacent)
                    }
                }
            }
            openList.splice(openList.indexOf(current), 1)
            closedList.push(current)
            if(openList.length > 0) {
                current = openList[0]
            }
        }

        var path = []
        path.push(Qt.point(target.i, target.j))
        while(current.cameFrom !== null) {
            current = current.cameFrom
            path.push(Qt.point(current.i, current.j))
        }
        var finalTime = Date.now()
        var difference = finalTime - currentTime
        console.log("Found path in " + difference + " ms")
        return path
    }
}
