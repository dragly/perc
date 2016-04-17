import QtQuick 2.0
import Perc 1.0

import "defaults.js" as Defaults

PercObject {
    id: entityRoot

    signal requestSelection(var object)
    signal advance(real currentTime)
    signal move(real currentTime)
    signal performAction(var row, var column)
    signal killed(var object)

    property int entityId: -1
    property string objectName: "BaseEntity"
    property string filename: "BaseEntity.qml"
    property int row: 0
    property int col: 0
    property string informationText: "Not set"
    property bool selected: false
    property double lastTime: Date.now()
    property double animationDuration: 400
    property var entityManager: null
    property var percolationSystem: null
    property Team team: null
    property int teamId: -1
    property bool _isKilled: false
    property bool toBeDeleted: false
    property double healthPoints: 100.0

    x: col * Defaults.GRID_SIZE
    y: row * Defaults.GRID_SIZE

    function kill() {
        _isKilled = true
        killed(entityRoot)
    }

    persistentProperties: QtObject {
        property alias row: entityRoot.row
        property alias column: entityRoot.col
        property alias filename: entityRoot.filename
        property alias entityId: entityRoot.entityId
        property alias teamId: entityRoot.teamId
        property alias healthPoints: entityRoot.healthPoints
    }

    property Component controls

    Component.onCompleted: {
        if(filename === "BaseEntity.qml" || objectName === "BaseEntity") {
            throw("You need to set the objectName and filename if you inherit from BaseEntity.")
        }
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

    Rectangle {
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: -24
        }
        height: 24
        color: "black"

        Rectangle {
            id: lifeLeft
            anchors {
                left: parent.left
                top: parent.top
                bottom: parent.bottom
                margins: 4
            }
            width: entityRoot.healthPoints / 100.0 * parent.width - anchors.margins * 2
            color: "green"
        }

        Rectangle {
            anchors {
                left: lifeLeft.right
                right: parent.right
                top: parent.top
                bottom: parent.bottom
                margins: 4
            }
            color: "red"
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
