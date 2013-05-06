import QtQuick 2.0
import com.dragly.perc 1.0

import "logic.js" as Logic

Item {
    id: sceneRoot

    property alias imageType: percolationSystem.imageType
    property double lastUpdateTime: -1
    property var selectedObjects: []
    property real targetScale: scale
    readonly property alias currentScale: scaleTransform.xScale
    property alias scaleOriginX: scaleTransform.origin.x
    property alias scaleOriginY: scaleTransform.origin.y

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
        },
        Translate {
            id: positionTransform
        }
    ]

    onTargetScaleChanged: {
        scaleTransform.xScale = targetScale
        scaleTransform.yScale = targetScale
        selectionIndicator.refresh()
    }

//    onSelectedObjectsChanged: {
//        selectedObjectsChangedForReal()
//    }

    function selectObject(abs) {
        var objects = []
        objects.push(abs)
        selectedObjects = objects
    }

    onSelectedObjectsChanged: {
        selectionIndicator.refresh()
    }

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

        MouseArea {
            anchors.fill: parent
            onClicked: {
                selectedObjects = []
            }
        }
    }

    onImageTypeChanged: {
        percolationSystem.update()
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

    Rectangle {
        id: selectionIndicator

        property var selectedObjects: sceneRoot.selectedObjects
//        property double targetWidth: 10 //(mySelectedObject !== null) ? Math.max(mySelectedObject.width + 5, 10 / gameScene.targetScale) : 0
//        property double targetHeight: 10 //(mySelectedObject !== null) ? Math.max(mySelectedObject.width + 5, 10 / gameScene.targetScale) : 0

        color: "transparent"
        border.color: "white"
        border.width: Math.max(1, 1 / gameScene.targetScale)
        anchors.centerIn: (selectedObjects.length > 0) ? selectedObjects[0] : parent
        z: 9999
        width: 10
        height: 10

        onSelectedObjectsChanged: {
            refresh()
        }

        function refresh() {
            if(selectedObjects.length > 0) {
                visible = true
                anchors.centerIn = selectedObjects[0]
                width = Math.max(selectedObjects[0].width + 5, 10 / gameScene.targetScale)
                height = Math.max(selectedObjects[0].height + 5, 10 / gameScene.targetScale)
            } else {
                visible = false
            }
        }

        SequentialAnimation {
            running: true
            loops: Animation.Infinite
            ColorAnimation { target: selectionIndicator; property: "border.color"; from: "white"; to: "black"; duration: 200; easing.type: Easing.InOutQuad }
            ColorAnimation { target: selectionIndicator; property: "border.color"; from: "black"; to: "white"; duration: 200; easing.type: Easing.InOutQuad }
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
