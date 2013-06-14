import QtQuick 2.0

import ".."
import "../defaults.js" as Defaults

EntityBase {
    property string color

    property double moveInterval: 200
    property double lastTime: Date.now()
    property Team team: null

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

    function move(currentTime) {
//        console.log("Move not implemented for walker...")
    }

    Image {
        id: rect
        anchors.fill: parent
        source: "walker.png"
    }

//    property alias lightSource: nMapEffect.lightSource
    property var lightSource

//    Rectangle {
//        id: rect
//        color: "#F03B20"
//        anchors.fill: parent
//    }

//    NMapEffect {
//        anchors.fill: parent
//        id: nMapEffect
//        anchors.centerIn: parent
//        elementPositionX: parent.x // + parent.width / 2
//        elementPositionY: parent.y // + parent.height / 2
//        sourceImage: "images/ape.png"
//        normalsImage: "images/apen.png"
////        lightSource: lightSource
//        diffuseBoost: 0.4
//        switchX: false
//        switchY: false
//        width: nMapEffect.originalWidth
//        height: nMapEffect.originalHeight
//    }
}
