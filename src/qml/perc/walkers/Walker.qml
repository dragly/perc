import QtQuick 2.0

import ".."
import "../defaults.js" as Defaults

EntityBase {
    objectName: "Walker"
    property alias color: rect.color
    property double moveInterval: 200
    property double lastTime: Date.now()

    function move(currentTime) {
        console.log("Move not implemented for walker...")
    }

    Component.onCompleted: {
        if(team === null) {
            throw "Walker created without a team"
        }
    }

    smooth: true

    width: Defaults.GRID_SIZE * 0.7
    height: Defaults.GRID_SIZE * 0.7

    x: col * Defaults.GRID_SIZE + (Defaults.GRID_SIZE - width) / 2
    y: row * Defaults.GRID_SIZE + (Defaults.GRID_SIZE - width) / 2

    onAdvance: {
        var interval = currentTime - lastTime
        if(interval > moveInterval) {
            animationDuration = interval
            move(currentTime)
            lastTime = currentTime
        }
    }

    Rectangle {
        id: rect
        color: "#F03B20"
        anchors.fill: parent
    }
}
