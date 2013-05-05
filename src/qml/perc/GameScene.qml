import QtQuick 2.0
import com.dragly.perc 1.0

import "logic.js" as Logic

Item {
    id: sceneRoot
    width: 200
    height: 300

//    PercolationMatrix {
//        id: percolationMatrix
//        nRows: 200
//        nCols: 200
//    }

    PercolationSystem {
        id: percolationSystem
        width: 5000
        height: 5000
        z: -10
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
//            if(triggers > 10) {
//                percolationSystem.update()
//                triggers = 0
//            }
        }
    }

    Component.onCompleted: {
        percolationSystem.initialize(1000,1000,0.55)
        for(var i = 0; i < 200; i++) {
            Logic.createRandomWalker()
            Logic.createDirectionWalker("left")
            Logic.createDirectionWalker("right")
        }
    }
}
