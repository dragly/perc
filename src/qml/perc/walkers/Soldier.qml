import QtQuick 2.0
import "../movement"

Walker {
    property alias target: astar.target
    objectName: "Soldier"
    AStarMover {
        id: astar
    }
//    RandomMover {

//    }
}
