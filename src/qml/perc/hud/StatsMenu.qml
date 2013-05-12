import QtQuick 2.0
import QtGraphicalEffects 1.0

Item {
    id: statsMenuRoot



    anchors.left: parent.left
    anchors.top: parent.top
    anchors.leftMargin: -width * 0.1

    width: parent.width * 0.2
    height: parent.height * 0.15
    state: "active"

    Item {
        id: backgroundContainer
        anchors.centerIn: parent
        width: gameMenuBackground.width + shadow.radius * 2
        height: gameMenuBackground.height + shadow.radius * 2

        Rectangle {
            id: gameMenuBackground
            color: "#DFAFAFAF"
            radius: statsMenuRoot.width * 0.05
            anchors.centerIn: parent
            width: statsMenuRoot.width
            height: statsMenuRoot.height
            smooth: true
        }

        visible: false
    }

    DropShadow {
        id: shadow
        anchors.fill: backgroundContainer
        source: backgroundContainer
        radius: 20
        horizontalOffset: 5
        verticalOffset: 5
        samples: 16
        color: "#80000000"
        smooth: true
        cached: true
    }

    Behavior on anchors.topMargin {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutQuad
        }
    }
    states: [
        State {
            name: "active"
            PropertyChanges {
                target: statsMenu
                anchors.topMargin: -statsMenuRoot.height * 0.1
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: statsMenu
                anchors.topMargin: -statsMenu.height * 0.8
            }
        }
    ]
}
