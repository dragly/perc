import QtQuick 2.0
import com.dragly.perc 1.0

import "logic.js" as Logic

Item {
    id: sceneRoot
    width: 200
    height: 300

    PercolationMatrix {
        id: percolationMatrix
        nRows: 500
        nCols: 500
    }

    PercolationSystem {
        id: percolationSystem
    }

    Timer {
        id: advanceTimer
        running: true
        interval: 200
        repeat: true
        onTriggered: {
            Logic.moveWalkers()
        }
    }

    Component.onCompleted: {
        percolationSystem.initialize(percolationMatrix.nRows,percolationMatrix.nCols,0.5)
        for(var i = 0; i < 200; i++) {
            Logic.createRandomWalker()
            Logic.createDirectionWalker("left")
            Logic.createDirectionWalker("right")
        }
    }
}
