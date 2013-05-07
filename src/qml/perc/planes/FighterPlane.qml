import QtQuick 2.0
import QtGraphicalEffects 1.0

import ".."
import "../defaults.js" as Defaults

EntityBase {
    id: fighterPlaneRoot
    width: Defaults.GRID_SIZE * 0.5
    height: Defaults.GRID_SIZE * 0.7

    Item {
        id: imageContainer
        anchors.centerIn: parent
        width: image.width + shadow.radius * 2
        height: image.height + shadow.radius * 2
        Image {
            id: image
            source: "fighterplane.png"
            anchors.centerIn: imageContainer
            width: fighterPlaneRoot.width
            height: fighterPlaneRoot.height
        }
        visible: false
    }

    DropShadow {
        id: shadow
        anchors.fill: imageContainer
        source: imageContainer
        horizontalOffset: 50
        verticalOffset: 60
        samples: 16
        radius: 6
        color: "#80000000"
        smooth: true
        cached: true
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            console.log("Clicked plane!")
        }
    }

//    transform: [
//        Rotation {
//            id: flightRotationDummy
//            origin.x: Defaults.GRID_SIZE * 4
//            origin.y: Defaults.GRID_SIZE * 4
//            angle: 0
//        }
//    ]

    Behavior on rotation {
        NumberAnimation {
            duration: Defaults.TIME_STEP * 2
        }
    }

    Timer {
        running: true
        repeat: true
        interval: 200
        onTriggered: {
            if(col > 10) {
                row += 1
                rotation = 180
            } else {
                col += 1
                rotation = 90
            }
        }
    }
}
