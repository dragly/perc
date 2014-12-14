import QtQuick 2.0
import QtGraphicalEffects 1.0
import org.dragly.perc 1.0

Item {
    id: gameMenuRoot

    property int imageType: PercolationSystem.AreaImage
    property double energy
    signal pauseClicked

    anchors.right: parent.right
    anchors.top: parent.top
    height: parent.height * 0.6
    width: parent.width * 0.2

    state: "hidden"

    states: [
        State {
            name: "active"
            PropertyChanges {
                target: gameMenuRoot
                anchors.rightMargin: 0
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: gameMenuRoot
                anchors.rightMargin: -gameMenuRoot.width * 0.9
            }
        }
    ]

    Behavior on anchors.rightMargin {
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
        id: switchImageTypeButton
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.width * 0.3
        width: parent.width * 0.3
        anchors.top: parent.top
        anchors.topMargin: parent.width * 0.2
        color: "blue"

        MouseArea {
            anchors.fill: parent

            onClicked: {
                if(imageType === PercolationSystem.PressureImage) {
                    imageType = PercolationSystem.MovementCostImage
                } else if(imageType === PercolationSystem.MovementCostImage) {
                    imageType = PercolationSystem.AreaImage
                } else if(imageType === PercolationSystem.AreaImage) {
                    imageType = PercolationSystem.PressureImage
                }
            }
        }
    }

    Rectangle {
        id: returnToMainMenuButton
        anchors.horizontalCenter: parent.horizontalCenter
        height: parent.width * 0.3
        width: parent.width * 0.3
        anchors.top: switchImageTypeButton.bottom
        anchors.topMargin: parent.width * 0.2
        color: "red"

        MouseArea {
            anchors.fill: parent

            onClicked: {
                pauseClicked()
            }
        }
    }

    Text {
        text: "Energy: " + (Math.round(gameMenuRoot.energy * 100) / 100).toFixed(2)
        font.pixelSize: parent.width * 0.1
        anchors.top: returnToMainMenuButton.bottom
        anchors.left: parent.left
        anchors.leftMargin: parent.width*0.2
    }
}
