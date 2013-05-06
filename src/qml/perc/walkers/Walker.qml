import QtQuick 2.0

import ".."

EntityBase {
    property int row: -1
    property int col: -1
    property alias color: rect.color

    Rectangle {
        id: rect
        color: "#F03B20"
        anchors.fill: parent
    }
    smooth: true

    width: 3
    height: 3

    x: col * 10 + (10 - width) / 2
    y: row * 10 + (10 - width) / 2


    Behavior on x {
        NumberAnimation {
            duration: 200
//            easing.type: Easing.InOutQuad
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: 200
//            easing.type: Easing.InOutQuad
        }
    }

    function move() {
        console.log("Move not implemented for walker...")
    }
}
