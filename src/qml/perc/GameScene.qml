import QtQuick 2.0
import com.dragly.perc 1.0

import "logic.js" as Logic

Item {
    id: sceneRoot

    property alias imageType: percolationSystem.imageType

    width: 200
    height: 300

    PercolationSystem {
        id: percolationSystem
        width: nCols
        height: nRows
        nRows: 300
        nCols: 2000
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

    onImageTypeChanged: {
        percolationSystem.update()
    }

    Timer {
        id: percolationRefresh
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
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
            Logic.refreshPressures()
//            percolationSystem.recalculateMatricesInThread()
            percolationSystem.update()
            triggers += 1
            if (triggers > 10) {
//                Logic.refreshClusters()
                triggers = 0
            }
        }
    }

    Component.onCompleted: {
        percolationSystem.initialize()
        for (var i = 0; i < 100; i++) {
            Logic.createRandomWalker("raise")
            Logic.createRandomWalker("lower")
            Logic.createDirectionWalker("left")
            Logic.createDirectionWalker("right")
            Logic.createPressureSource()
        }
    }
}
