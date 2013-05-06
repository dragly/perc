import QtQuick 2.0
import com.dragly.perc 1.0

import "logic.js" as Logic

Item {
    id: sceneRoot

    property alias imageType: percolationSystem.imageType
    property double lastUpdateTime: -1

    width: 200
    height: 300

    PercolationSystem {
        id: percolationSystem
        width: nCols
        height: nRows
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

    Text {
        id: updatesPerSecondText
        property double ups: 0
        anchors.top: parent.top
        anchors.left: parent.left
        color: "white"
        font.pixelSize: parent.height * 0.05
        text: "UPS: " + parseFloat(Math.round(ups * 100) / 100).toFixed(2)
    }

    Timer {
        property int triggers: 0
        id: advanceTimer
        running: true
        interval: 1000 / 60 // hoping for 60 FPS
        repeat: true
        onTriggered: {
            var currentUpdateTime = Date.now()
            var currentInterval = currentUpdateTime - lastUpdateTime
            if(currentInterval > 200) {
                if(percolationSystem.tryLockUpdates()) {
                    Logic.moveWalkers()
                    Logic.refreshPressures()
                    percolationSystem.unlockUpdates()
                    percolationSystem.update()
                    lastUpdateTime = currentUpdateTime
                    updatesPerSecondText.ups = 1000 / currentInterval
                }
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
