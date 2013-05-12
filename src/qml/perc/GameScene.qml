import QtQuick 2.0
import com.dragly.perc 1.0

import "logic.js" as Logic
import "defaults.js" as Defaults

Item {
    id: sceneRoot

    property alias imageType: percolationSystem.imageType
    property double lastUpdateTime: Date.now()
    property var selectedObjects: []
    property real targetScale: scale
    readonly property alias currentScale: scaleTransform.xScale
    property alias scaleOriginX: scaleTransform.origin.x
    property alias scaleOriginY: scaleTransform.origin.y
    property alias lightSource: lightSource

    transform: [
        Scale {
            id: scaleTransform

            property int scaleDuration: 50

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
        lightIntensity: 5
        anchors.centerIn: parent
    }

    onTargetScaleChanged: {
        if(targetScale > 1) {
            targetScale = 1
        }
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

    width: percolationSystem.width * Defaults.GRID_SIZE
    height: percolationSystem.height * Defaults.GRID_SIZE

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
            xScale: Defaults.GRID_SIZE
            yScale: Defaults.GRID_SIZE
        }

        smooth: false

        onReadyToUpdate: {
            percolationSystem.update()
        }

        z: -999
    }

//    TestPercolationEffect {
//        id: percolationSystem
//        width: nCols
//        height: nRows
//        nRows: 50
//        nCols: 50
//        occupationTreshold: 0.55
//        lightSource: lightSource
//        z: -999
//        smooth: false
//        transform: Scale {
//            origin.x: 0
//            origin.y: 0
//            xScale: Defaults.GRID_SIZE
//            yScale: Defaults.GRID_SIZE
//        }
//    }

    Rectangle {
        id: selectionRectangle
        border.width: 1
        border.color: "white"
                color: Qt.rgba(1,1,1,0.4)
//        color: "white"
//        opacity: 0.1
        width: 100
        height: 100
        visible: mainMouseArea.isDragging
        onVisibleChanged: {
            console.log("Visible " + visible)
            console.log(x + " " + y + " " + width + " " + height)
        }

        z: 99999
    }

    onImageTypeChanged: {
        percolationSystem.update()
    }

    //    Text {
    //        id: updatesPerSecondText
    //        property double ups: 0
    //        anchors.top: parent.top
    //        anchors.left: parent.left
    //        color: "white"
    //        font.pixelSize: parent.height * 0.05
    //        text: "UPS: " + parseFloat(Math.round(ups * 100) / 100).toFixed(2)
    //    }

    EntityManager {
        id: entityManager
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
                    Logic.refreshPressures(currentInterval)
                    percolationSystem.unlockUpdates()
                    percolationSystem.requestRecalculation()
                    lastUpdateTime = currentUpdateTime
                }
            }
        }
    }

    MouseArea {
        id: mainMouseArea
        property bool isDragging: false

        anchors.fill: parent

        onClicked: {
            if(!isDragging) {
                console.log("clicked")
                selectedObjects = []
            }
        }

        onReleased: {
            isDragging = false
        }

        onPressed: {
            console.log("Pressed")
        }

        onPositionChanged: {
            lightSource.setLightPos(mouse.x, mouse.y)
            if(!isDragging) {
                isDragging = true
                selectionRectangle.x = mouse.x
                selectionRectangle.y = mouse.y
            } else {
                selectionRectangle.width = mouse.x - selectionRectangle.x
                selectionRectangle.height = mouse.y - selectionRectangle.y
            }
        }
        z: 99999999
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
        width: Defaults.GRID_SIZE
        height: Defaults.GRID_SIZE

        onSelectedObjectsChanged: {
            refresh()
        }

        function refresh() {
            if(selectedObjects !== undefined && selectedObjects.length > 0) {
                visible = true
                anchors.centerIn = selectedObjects[0]
                width = Math.max(selectedObjects[0].width + Defaults.GRID_SIZE * 0.25, Defaults.GRID_SIZE / (10 * gameScene.targetScale))
                height = Math.max(selectedObjects[0].height + Defaults.GRID_SIZE * 0.25, Defaults.GRID_SIZE / (10 * gameScene.targetScale))
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
        for (var i = 0; i < 5; i++) {
            Logic.createRandomWalker("raise")
            Logic.createRandomWalker("lower")
            Logic.createDirectionWalker("left")
            Logic.createDirectionWalker("right")
        }

        for(var i = 0; i < 5; i++) {
            Logic.createPressureSource()
        }

        var plane = entityManager.createEntityFromUrl("planes/FighterPlane.qml")
    }
}
