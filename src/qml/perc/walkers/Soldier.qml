import QtQuick 2.0
import ".."
import "../movement"
import "../defaults.js" as Defaults

EntityBase {
    property alias target: astar.target
    objectName: "Soldier"
    filename: "walkers/Soldier.qml"

    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    AStarMover {
        id: astar
    }
}
