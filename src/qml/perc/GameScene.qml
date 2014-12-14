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
    property real targetScale: scale
    readonly property alias currentScale: scaleTransform.yScale
    property alias scaleOriginX: scaleTransform.origin.x
    property alias scaleOriginY: scaleTransform.origin.y
    property alias lightSource: lightSource

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
        console.log(targetScale)
        scaleTransform.xScale = targetScale
        scaleTransform.yScale = targetScale
    }

    transform: [
        Scale {
            id: scaleTransform

            property int scaleDuration: 200

            Behavior on xScale {
                NumberAnimation {
                    duration: scaleTransform.scaleDuration
                    easing.type: Easing.OutQuad
                }
            }

            Behavior on yScale {
                NumberAnimation {
                    duration: scaleTransform.scaleDuration
                    easing.type: Easing.OutQuad
                }
            }
        }
    ]

    NMapLightSource {
        id: lightSource
        z: 10
        lightIntensity: 0.5
        anchors.centerIn: parent
    }
}
