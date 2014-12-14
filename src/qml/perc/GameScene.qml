import QtQuick 2.0
import org.dragly.perc 1.0

import "logic.js" as Logic
import "defaults.js" as Defaults

Item {
    id: sceneRoot

    width: 100
    height: 62

//    property alias imageType: percolationSystem.imageType
    property PercolationSystem percolationSystem: null
    property real targetScale: 1.0
    property real currentScale: 1.0
    property alias scaleOriginX: scaleTransform.origin.x
    property alias scaleOriginY: scaleTransform.origin.y
//    property alias lightSource: lightSource
    property int scaleDuration: 200

    Component.onCompleted: {
        if(percolationSystem === null) {
            console.log("Error: PercolationSystem must be set in GameScene")
            Qt.quit()
            return
        }
    }

    onTargetScaleChanged: {
        if(targetScale > 1) {
            targetScale = 1
        }
        scaleAnimation.from = currentScale
        scaleAnimation.to = targetScale
        scaleAnimation.restart()
    }

    PropertyAnimation {
        id: scaleAnimation
        target: sceneRoot
        properties: "currentScale"
        duration: scaleDuration
        easing.type: Easing.OutQuad
    }

    transform: [
        Scale {
            id: scaleTransform

            xScale: currentScale
            yScale: currentScale
        }
    ]
}
