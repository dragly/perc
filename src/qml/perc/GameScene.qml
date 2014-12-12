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
    property list<EntityBase> selectedObjects
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

        onExited: {
            console.log("Exited")
        }

//        onReleased: {
//            console.log("Released")
//            if(isDragging) {
//                var newSelection;
//                if(mouse.modifiers & Qt.ShiftModifier) {
//                    newSelection = sceneRoot.selectedObjects
//                } else {
//                    newSelection = []
//                }
//                for(var i in entityManager.entities) {
//                    var entity = entityManager.entities[i]
//                    var rect = selectionRectangle
//                    if(entity.x > rect.x && entity.x < rect.x + rect.width && entity.y > rect.y && entity.y < rect.y + rect.height) {
//                        newSelection.push(entity)
//                    } else {
//                        entity.selected = false
//                    }
//                }
//                for(var i in newSelection) {
//                    var entity = newSelection[i]
//                    entity.selected = true
//                }

//                sceneRoot.selectedObjects = newSelection
//            } else {
//                selectedObjects = []
//            }
//            selectionRectangle.width = 1
//            selectionRectangle.height = 1
//            isDragging = false
//        }

//        onPressed: {
//            console.log("Pressed")
//            isDragging = true
//            dragStart.x = mouse.x
//            dragStart.y = mouse.y

//        }

//        onPositionChanged: {
//            if(isDragging) {
//                if(mouse.x > dragStart.x) {
//                    selectionRectangle.x = dragStart.x
//                    selectionRectangle.width = mouse.x - dragStart.x
//                } else {
//                    selectionRectangle.x = mouse.x
//                    selectionRectangle.width = dragStart.x - mouse.x
//                }
//                if(mouse.y > dragStart.y) {
//                    selectionRectangle.y = dragStart.y
//                    selectionRectangle.height = mouse.y - dragStart.y
//                } else {
//                    selectionRectangle.y = mouse.y
//                    selectionRectangle.height = dragStart.y - mouse.y
//                }
//            }
//        }

        drag.target: parent
        z: 9999999
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

    NMapLightSource {
        id: lightSource
        z: 10
        lightIntensity: 0.5
        anchors.centerIn: parent
    }
}
