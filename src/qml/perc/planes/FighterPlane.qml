import QtQuick 2.0
import QtGraphicalEffects 1.0

import ".."

EntityBase {
    id: fighterPlaneRoot
    width: 30
    height: 40

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
            sourceSize.width: 120
            sourceSize.height: 160
            smooth: true
            fillMode: Image.Stretch
        }
        visible: false
        smooth: true
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
            console.log(fighterPlaneRoot.parent.targetScale)
//            image.sourceSize.width = fighterPlaneRoot.parent.targetScale * 30
//            image.sourceSize.height = fighterPlaneRoot.parent.targetScale * 40
            parent.width = fighterPlaneRoot.parent.targetScale * 30
            parent.height = fighterPlaneRoot.parent.targetScale * 40
        }
    }
}
