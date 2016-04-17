import QtQuick 2.0
import org.dragly.perc 1.0

import "logic.js" as Logic
import "defaults.js" as Defaults

Item {
    id: sceneRoot

    width: 100
    height: 62

    default property alias containerChildren: entityContainer.children

    property PercolationSystem percolationSystem: null
    property var entityManager: null // TODO should be EntityManager
    property list<EntityBase> selectedObjects
    property real targetScale: scale
    readonly property alias currentScale: scaleTransform.yScale
    property alias scaleOriginX: scaleTransform.origin.x
    property alias scaleOriginY: scaleTransform.origin.y
    property alias lightSource: lightSource

    Component.onCompleted: {
        if(percolationSystem === null || entityManager === null) {
            throw("Error: PercolationSystem and entityManager must be set in GameScene")
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

        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        anchors.fill: parent

        onExited: {
            console.log("Exited")
        }

        onClicked: {
            console.log("Clicked")
            switch(mouse.button) {
            case Qt.LeftButton:
                selectedObjects = [];
                break;
            case Qt.RightButton:
                for(var i in selectedObjects) {
                    var selectedObject = selectedObjects[i];
                    var row = parseInt(Math.floor(mouse.y / Defaults.GRID_SIZE));
                    var column = parseInt(Math.floor(mouse.x / Defaults.GRID_SIZE));
                    selectedObject.performAction(row, column);
                }
            }
        }

        drag.target: parent
    }

    NMapLightSource {
        id: lightSource
        z: 10
        lightIntensity: 0.5
        anchors.centerIn: parent
    }

    Item {
        id: entityContainer
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
    }
}
