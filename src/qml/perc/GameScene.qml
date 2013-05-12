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
    property real energy: 0

    function addEnergy(amount) {
        energy += amount
    }

    function requestSelection(object) {
        for(var i in entityManager.entities) {
            var other = entityManager.entities[i]
            other.selected = false
        }
        var objects = []
        objects.push(object)
        object.selected = true

        selectedObjects = objects
    }

    onTargetScaleChanged: {
        if(targetScale > 1) {
            targetScale = 1
        }
        console.log(targetScale)
        scaleTransform.xScale = targetScale
        scaleTransform.yScale = targetScale
    }

    onSelectedObjectsChanged: {
        //        selectionIndicator.refresh()
    }

    width: percolationSystem.width * Defaults.GRID_SIZE
    height: percolationSystem.height * Defaults.GRID_SIZE

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

    PercolationSystem {
        id: percolationSystem
        width: nCols
        height: nRows
        nRows: 100
        nCols: 100
        occupationTreshold: 0.4

        transform: Scale {
            origin.x: 0
            origin.y: 0
            xScale: Defaults.GRID_SIZE
            yScale: Defaults.GRID_SIZE
        }

        smooth: false

        z: -999
    }

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
            //            selectionIndicator.refresh()
        }
    }

    MouseArea {
        id: mainMouseArea
        property bool isDragging: false
        property point dragStart

        propagateComposedEvents: true
        hoverEnabled: true

        anchors.fill: parent
        //        onClicked: {
        //            if(!isDragging) {
        //                console.log("clicked")
        //                selectedObjects = []
        //            }
        //        }

        onReleased: {
            if(isDragging) {
                var newSelection = []
                for(var i in entityManager.entities) {
                    var entity = entityManager.entities[i]
                    var rect = selectionRectangle
                    if(entity.x > rect.x && entity.x < rect.x + rect.width && entity.y > rect.y && entity.y < rect.y + rect.height) {
                        newSelection.push(entity)
                        entity.selected = true
                    } else {
                        entity.selected = false
                    }
                }
                sceneRoot.selectedObjects = newSelection
            } else {
                selectedObjects = []
            }
            selectionRectangle.width = 1
            selectionRectangle.height = 1
            isDragging = false
        }

        onPressed: {
            console.log("Pressed")
            isDragging = true
            dragStart.x = mouse.x
            dragStart.y = mouse.y
        }

        onPositionChanged: {
            if(isDragging) {
                if(mouse.x > dragStart.x) {
                    selectionRectangle.x = dragStart.x
                    selectionRectangle.width = mouse.x - dragStart.x
                } else {
                    selectionRectangle.x = mouse.x
                    selectionRectangle.width = dragStart.x - mouse.x
                }
                if(mouse.y > dragStart.y) {
                    selectionRectangle.y = dragStart.y
                    selectionRectangle.height = mouse.y - dragStart.y
                } else {
                    selectionRectangle.y = mouse.y
                    selectionRectangle.height = dragStart.y - mouse.y
                }
            }
        }
    }

    Rectangle {
        id: selectionRectangle
        border.width: 1
        border.color: "white"
        color: Qt.rgba(1,1,1,0.4)
        //        color: "white"
        //        opacity: 0.1
        width: 0
        height: 0
        visible: mainMouseArea.isDragging

        z: 99999
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

    NMapLightSource {
        id: lightSource
        z: 10
        lightIntensity: 2
        anchors.centerIn: parent
    }
}
