import QtQuick 2.0
import com.dragly.perc 1.0

import "logic.js" as Logic

Rectangle {
    id: sceneRoot
    width: 200
    height: 300
    color: "yellow"
    Rectangle {
        x: 20
        y: 30
        color: "red"
        width: 100
        height: 100
    }

    PercolationMatrix {
        id: percolationMatrix
    }

    PercolationSystem {
        id: percolationSystem
    }

    Timer {
        id: advanceTimer
        running: true
        interval: 100
        repeat: true
        onTriggered: {
            Logic.moveWalkers()
        }
    }

    Component.onCompleted: {
        percolationSystem.initialize(200,200,0.6)
        Logic.populate()
        Logic.createRandomWalker()
        Logic.createDirectionWalker(0)
    }
}
