import QtQuick 2.0

import ".."
import "../defaults.js" as Defaults

EntityBase {
    property alias color: rect.color

    Rectangle {
        id: rect
        color: "#F03B20"
        anchors.fill: parent
    }
    smooth: true

    width: Defaults.GRID_SIZE * 0.3
    height: Defaults.GRID_SIZE * 0.3

    x: col * Defaults.GRID_SIZE + (Defaults.GRID_SIZE - width) / 2
    y: row * Defaults.GRID_SIZE + (Defaults.GRID_SIZE - width) / 2

    function move() {
        console.log("Move not implemented for walker...")
    }
}
