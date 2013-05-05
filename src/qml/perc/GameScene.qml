import QtQuick 2.0
import com.dragly.perc 1.0

import "logic.js" as Logic

Item {
    id: sceneRoot
    width: 200
    height: 300

    PercolationSystem {
        id: percolationSystem
        width: 500
        height: 500
        nRows: 500
        nCols: 500
        occupationTreshold: 0.55
        transform: Scale {
            origin.x: 0
            origin.y: 0
            xScale: 10
            yScale: 10
        }

        smooth: false
        z: -10
    }

    Timer {
        id: percolationRefresh
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            percolationSystem.recalculateMatricesInThread()
        }
    }

    Timer {
        property int triggers: 0
        id: advanceTimer
        running: true
        interval: 200
        repeat: true
        onTriggered: {
            Logic.moveWalkers()
            triggers += 1
            if (triggers > 10) {
                percolationSystem.update()
                triggers = 0
            }
        }
    }

    Component.onCompleted: {
        percolationSystem.initialize()
        for (var i = 0; i < 10; i++) {
            Logic.createRandomWalker("raise")
            Logic.createRandomWalker("lower")
            Logic.createDirectionWalker("left")
            Logic.createDirectionWalker("right")
        }
    }
}
