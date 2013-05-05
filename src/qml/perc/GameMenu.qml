import QtQuick 2.0
import QtGraphicalEffects 1.0
import com.dragly.perc 1.0

Item {
    id: gameMenuRoot

    property int imageType: PercolationSystem.PressureImage

    anchors.left: parent.left
    height: parent.height * 0.8
    width: parent.width * 0.1
    anchors.verticalCenter: parent.verticalCenter

    state: "hidden"

    states: [
        State {
            name: "active"
            PropertyChanges {
                target: gameMenuRoot
                anchors.leftMargin: 0
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: gameMenuRoot
                anchors.leftMargin: -gameMenuRoot.width * 0.8
            }
        }
    ]

    Behavior on anchors.leftMargin {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutQuad
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onHoveredChanged: {
            if(containsMouse) {
                gameMenuRoot.state = "active"
            } else {
                gameMenuRoot.state = "hidden"
            }
        }
    }

    clip: false

    Item {
        id: backgroundContainer
        anchors.centerIn: parent
        width: gameMenuBackground.width + shadow.radius * 2
        height: gameMenuBackground.height + shadow.radius * 2

        Rectangle {
            id: gameMenuBackground
            color: "white"
            anchors.centerIn: parent
            width: gameMenuRoot.width
            height: gameMenuRoot.height
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

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.width * 0.8
        width: parent.width * 0.8
        anchors.top: parent.top
        anchors.topMargin: parent.width * 0.2
        color: "blue"

        MouseArea {
            anchors.fill: parent

            onClicked: {
                if(imageType === PercolationSystem.PressureImage) {
                    imageType = PercolationSystem.AreaImage
                } else {
                    imageType = PercolationSystem.PressureImage
                }
            }
        }
    }
}
