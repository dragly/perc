import QtQuick 2.0

import ".."
import "../movement"
import "../defaults.js" as Defaults

EntityBase {
    signal chooseStrategy

    property string strategy: "none"
    property int moveStrategy: 0
    property bool walker: true
    property var directions: [
                {row: 1, column: 0},
                {row: 0, column: 1},
                {row: -1, column: 0},
                {row: 0, column: -1}
            ];

    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    function strategyType(strategy) {
        if(strategy >= 0 && strategy < 4) {
            return "directional";
        }
        return "nothing";
    }

    function moveDirection(moveStrategy) {
        moveStrategy = Math.max(0, Math.min(3, moveStrategy));
        return directions[moveStrategy];
    }

    function moveResult(moveStrategy) {
        var direction = moveDirection(moveStrategy);
        return {
            row: row + direction.row,
            column: col + direction.column
        };
    }

    function moveAcceptable(moveStrategy) {
        var result = moveResult(moveStrategy);
        console.log("Testing", moveStrategy, "resulting in", result.row, result.column);
        console.log("Cost:", percolationSystem.movementCost(result.row, result.column))
        if(percolationSystem.movementCost(result.row, result.column) > 0) {
            console.log("Accepted");
            return true;
        }
        console.log("Denied");
        return false;
    }

    function changeToDirection(rowChange, columnChange) {
        if(Math.abs(rowChange) + Math.abs(columnChange) !== 1) {
            console.warn("WARNING: Directions can not be diagonal or zero.")
            return -1;
        }
        if(rowChange === 1) {
            return 0;
        }
        if(columnChange === 1) {
            return 1;
        }
        if(rowChange === -1) {
            return 2;
        }
        if(columnChange === -1) {
            return 3;
        }
    }

    onMove: {
        console.log("----- Server testing strategy -----");
        var rowChange = 0;
        var columnChange = 0;
        if(strategy === "move") {
            console.log("Received strategy", moveStrategy);
            if(moveAcceptable(moveStrategy)) {
                row = moveResult(moveStrategy).row;
                col = moveResult(moveStrategy).column;
            }
        }
    }

    Rectangle {
        id: rect
        color: team.color
        anchors.centerIn: parent

        width: Defaults.GRID_SIZE * 0.7
        height: Defaults.GRID_SIZE * 0.7
    }
}
