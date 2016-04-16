import QtQuick 2.0
import org.dragly.perc 1.0

import "defaults.js" as Defaults

Item {
    id: entityRoot

    signal requestSelection(var object)
    signal advance(real currentTime)
    signal move(real currentTime)
    signal killed(var object)

    property int entityId: -1
    property string objectName: "EntityBase"
    property string filename: "EntityBase.qml"
    property int row: 0
    property int col: 0
    property string informationText: "Not set"
    property bool selected: false
    property double lastTime: Date.now()
    property double animationDuration: 400
    property var entityManager: null
    property var percolationSystem: null
    property Team team: null
    property bool _isKilled: false
    property bool toBeDeleted: false

    x: col * Defaults.GRID_SIZE
    y: row * Defaults.GRID_SIZE

    function kill() {
        _isKilled = true
        killed(entityRoot)
    }

    property QtObject properties: QtObject {
        property alias row: entityRoot.row
        property alias column: entityRoot.col
        property alias filename: entityRoot.filename
        property alias entityId: entityRoot.entityId
    }

    Behavior on x {
        NumberAnimation {
            duration: entityRoot.animationDuration
            easing.type: Easing.Linear
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: entityRoot.animationDuration
            easing.type: Easing.Linear
        }
    }

    Behavior on rotation {
        NumberAnimation {
            duration: entityRoot.animationDuration
            easing.type: Easing.Linear
        }
    }

    Rectangle {
        id: selectionIndicator
        anchors.centerIn: entityRoot
        visible: entityRoot.selected

        color: "transparent"

        border.color: "white"
        border.width: Math.max(1, 1 / gameScene.targetScale)
        width: Math.max(entityRoot.width + Defaults.GRID_SIZE * 0.25, Defaults.GRID_SIZE / (10 * gameScene.targetScale))
        height: Math.max(entityRoot.height + Defaults.GRID_SIZE * 0.25, Defaults.GRID_SIZE / (10 * gameScene.targetScale))

        SequentialAnimation {
            running: selectionIndicator.visible
            loops: Animation.Infinite
            ColorAnimation { target: selectionIndicator; property: "border.color"; from: "white"; to: "black"; duration: 200; easing.type: Easing.InOutQuad }
            ColorAnimation { target: selectionIndicator; property: "border.color"; from: "black"; to: "white"; duration: 200; easing.type: Easing.InOutQuad }
        }
    }

    MouseArea {
        anchors.centerIn: parent
        width: parent.width + Defaults.GRID_SIZE * 0.25
        height: parent.height + Defaults.GRID_SIZE * 0.25
        onClicked: {
            console.log(entityRoot.x)
            requestSelection(entityRoot)
        }
    }
}
