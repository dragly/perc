import QtQuick 2.0
import ".."

Mover {
    property var path: []
    property EntityBase target: null

    onMove: {
        if(!target) {
            return
        }
        if(path.length === 0) {
            path = findPath(Qt.point(parent.row, parent.col), Qt.point(target.row, target.col))
        }
        var next = path.pop()
        parent.row = next.x
        parent.col = next.y
    }

    function containsSquare(list, square) {
        for(var i in list) {
            var otherSquare = list[i]
            if(square.i === otherSquare.i && square.j === otherSquare.j) {
                return otherSquare
            }
        }
        return false
    }

    function square(i,j) {
        return {i: i, j: j, G: 0, H: 0, F: 0, cameFrom: null}
    }

    function findPath(startPoint, targetPoint) {
        var currentTime = Date.now()
        console.log("Finding path!")
        var start = square(startPoint.x, startPoint.y)
        var target = square(targetPoint.x, targetPoint.y)
        var current = square(start.i, start.j)
        var openList = []
        var closedList = []
        openList.push(current)
        while(openList.length > 0) {
            if(current.i === target.i && current.j === target.j) {
                break
            }
            for(var di = -1; di < 2; di++) {
                for(var dj = -1; dj < 2; dj++) {
                    var i = current.i + di
                    var j = current.j + dj
                    var adjacent = square(i,j)
                    adjacent.cameFrom = current
                    if(!percolationSystem.inBounds(i,j)) {
                        continue
                    }
                    if(containsSquare(closedList, adjacent)) {
                        continue
                    }
                    if(!percolationSystem.isOccupied(i,j)) {
                        continue
                    }
                    // Disallow corner crossing
                    if(!(di === 0 || dj === 0)) {
                        var alti = current.i + di
                        var altj = current.j
                        if(!percolationSystem.isOccupied(alti, altj)) {
                            continue
                        }
                        alti = current.i
                        altj = current.j + dj
                        if(!percolationSystem.isOccupied(alti, altj)) {
                            continue
                        }
                    }

                    adjacent.G = current.G + Math.sqrt(di*di + dj*dj)
                    var deltaRow = target.i - adjacent.i
                    var deltaColumn = target.j - adjacent.j
                    adjacent.H = Math.sqrt(deltaRow*deltaRow + deltaColumn*deltaColumn)
                    adjacent.F = adjacent.G + adjacent.H
                    var existingSquare = containsSquare(openList, adjacent)
                    if(existingSquare) {
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
        while(current.cameFrom !== null) {
            current = current.cameFrom
            path.push(Qt.point(current.i, current.j))
        }
        path.push(Qt.point(target.i, target.j))
        var finalTime = Date.now()
        var difference = finalTime - currentTime
        console.log("Found path in " + difference)
        return path
    }
}
