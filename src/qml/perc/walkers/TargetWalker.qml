import QtQuick 2.0
import QtQuick.Controls 1.4

import ".."
import "../movement"
import "../defaults.js" as Defaults

BaseWalker {
    id: root

    property var path: []
    property var grid: []
    property bool targetEnabled: false
    property var target: {
        return {row: -1, col: -1}
    }
    property var modes: [
        "construct",
        "destruct",
        "target"
    ]
    property int modeIndex: 0
    readonly property string currentMode: modes[modeIndex]

    objectName: "TargetWalker"
    filename: "walkers/TargetWalker.qml"
    informationText: "Target walker. Right-click to move.\n" +
                     "Mode:" + modeIndex + "\n" +
                     "Strategy: " + strategy

    controls: Item {
        Button {
            text: "Mode: " + modes[modeIndex]
            onClicked: {
                var nextMode = modeIndex + 1;
                if(nextMode > modes.length - 1) {
                    nextMode = 0;
                }
                modeIndex = nextMode;
            }
        }
    }

    function createGrid() {
        var tmp = new Array(percolationSystem.rowCount)
        for(var i = 0; i < percolationSystem.rowCount; i++) {
            tmp[i] = new Array(percolationSystem.columnCount)
        }
        grid = tmp
    }

    function resetGrid() {
        for(var i = 0; i < percolationSystem.rowCount; i++) {
            for(var j = 0; j < percolationSystem.columnCount; j++) {
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
        return (list.indexOf(square) !== -1);
    }

    function square(i,j) {
        return {i: i, j: j, G: 0, H: 0, F: 0, cameFrom: null}
    }

    function findPath(startPoint, targetPoint) {
        console.log("Start pathfinding");
        resetGrid();
        var startTime = Date.now();
        var endTime = Date.now();
        var diff = endTime - startTime;
        var currentTime = Date.now();

        var start = grid[startPoint.x][startPoint.y];
        var target = grid[targetPoint.x][targetPoint.y];
        var current = grid[start.i][start.j];

        var openList = [];
        var closedList = [];
        openList.push(current);
        closedList.push(current);
        while(openList.length > 0) {
            if(current.i === target.i && current.j === target.j) {
                break;
            }
            for(var di = -1; di < 2; di++) {
                for(var dj = -1; dj < 2; dj++) {
                    // Don't include our own site
                    if(di === 0 && dj === 0) {
                        continue;
                    }
                    // No diagonal movement
                    if(!(di === 0 || dj === 0)) {
                        continue;
                    }

                    var i = current.i + di;
                    var j = current.j + dj;
                    if(!percolationSystem.inBounds(i,j)) {
                        continue;
                    }
                    if(!percolationSystem.movementCost(i,j) > 0) {
                        continue;
                    }
                    var adjacent = grid[i][j];
                    if(containsSquare(closedList, adjacent)) {
                        continue;
                    }
                    adjacent.cameFrom = current;
                    adjacent.G = current.G + Math.sqrt(di*di + dj*dj);
                    var deltaRow = target.i - adjacent.i;
                    var deltaColumn = target.j - adjacent.j;
                    adjacent.H = Math.sqrt(deltaRow*deltaRow + deltaColumn*deltaColumn);
                    adjacent.F = adjacent.G + adjacent.H;
                    var existingSquare = containsSquare(openList, adjacent);
                    if(containsSquare(openList, adjacent)) {
                        if(adjacent.F < existingSquare.F) {
                            openList.splice(openList.indexOf(existingSquare), 1);
                            openList.push(adjacent);
                        }
                    } else {
                        openList.push(adjacent);
                    }
                }
            }
            openList.splice(openList.indexOf(current), 1);
            closedList.push(current);
            if(openList.length > 0) {
                current = openList[0];
            }
        }

        console.log("Building final path");
        var path = [];
        path.push(Qt.point(target.i, target.j));
        while(current.cameFrom !== null) {
            current = current.cameFrom;
            path.push(Qt.point(current.i, current.j));
        }
        var finalTime = Date.now();
        var difference = finalTime - currentTime;
        console.log("Found path in " + difference + " ms");
        return path;
    }

    onChooseStrategy: {
        switch(currentMode) {
        case "construct":
            var randomIndex = parseInt(Math.random() * directions.length);
            var found = false;
            var result = moveResult(randomIndex);
            if(moveAcceptable(randomIndex) && percolationSystem.team(result.row, result.column) === team.teamId) {
                moveStrategy = randomIndex;
                strategy = "move";
            } else {
                strategy = "construct";
            }
            break;
        case "destruct":
            var randomIndex = parseInt(Math.random() * directions.length);
            var found = false;
            var result = moveResult(randomIndex);
            if(moveAcceptable(randomIndex)) {
                moveStrategy = randomIndex;
                strategy = "move";
            } else if (percolationSystem.team(row, col) !== team.teamId) {
                strategy = "destruct";
            } else {
                strategy = "none";
            }
            break;
        case "target":
            if(!target) {
                strategy = currentMode;
                return;
            }
            if(!targetEnabled) {
                strategy = currentMode;
                return;
            }

            console.log("Rows:", target.row, root.row, target.col, root.col);
            if(target.row === root.row && target.col === root.col) {
                strategy = currentMode;
                targetEnabled = false;
                return;
            }
            console.log("Path length:", path.length);
            if(path.length === 0) {
                path = findPath(Qt.point(root.row, root.col), Qt.point(target.row, target.col));
            }
            var next = path.pop();
            console.log("Next:", next);
            moveStrategy = changeToDirection(next.x - root.row, next.y - root.col);
            if(moveStrategy > -1) {
                strategy = "move";
            } else {
                strategy = "none";
            }
            break;
        default:
            strategy = "none";
            break
        }
    }

    onPerformAction: {
        console.log("Targeted", row, col)
        target.row = row;
        target.col = column;
        targetEnabled = true;
        path = [];
    }

    onPercolationSystemChanged: {
        createGrid();
    }
}
