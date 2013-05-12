import QtQuick 2.0

import ".."
import "../defaults.js" as Defaults

EntityBase {
    property string color
//    property alias lightSource: nMapEffect.lightSource

//    Rectangle {
//        id: rect
//        color: "#F03B20"
//        anchors.fill: parent
//    }
    Image {
        id: rect
        anchors.fill: parent
        source: "walker.png"
    }

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

    smooth: true

    width: Defaults.GRID_SIZE * 0.3
    height: Defaults.GRID_SIZE * 0.3

    x: col * Defaults.GRID_SIZE + (Defaults.GRID_SIZE - width) / 2
    y: row * Defaults.GRID_SIZE + (Defaults.GRID_SIZE - width) / 2

    function move() {
        console.log("Move not implemented for walker...")
    }
}
