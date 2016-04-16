import QtQuick 2.0

import ".."
import "../movement"
import "../defaults.js" as Defaults

EntityBase {
    property int strategy
    filename: "walkers/StrategyWalker.qml"

    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    Mover {
        onMove: {
            switch(strategy) {
            case 0:
                parent.row += 1;
                break;
            case 1:
                parent.col += 1;
                break;
            case 2:
                parent.row -= 1;
                break;
            case 3:
                parent.col -= 1;
                break;
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
