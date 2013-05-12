import QtQuick 2.0

import "defaults.js" as Defaults

Item {
    id: entityRoot
    property int row: 0
    property int col: 0
    property string informationText: "Not set"
    property bool selected: false
    signal requestSelection(var object)
    x: col * Defaults.GRID_SIZE
    y: row * Defaults.GRID_SIZE

    Behavior on x {
        NumberAnimation {
            duration: Defaults.TIME_STEP
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: Defaults.TIME_STEP * 1.1
        }
    }

    Behavior on rotation {
        NumberAnimation {
            duration: Defaults.TIME_STEP * 1.1
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
