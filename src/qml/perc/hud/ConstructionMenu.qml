import QtQuick 2.0
import QtGraphicalEffects 1.0
import Perc 1.0

import ".."

Item {
    id: gameMenuRoot

    property int imageType: imageTypes[currentImageTypeIndex]
    property string playerTeamName
    property color playerTeamColor
    property var teamAreas

    property int currentImageTypeIndex: 0
    property var imageTypes: [
        PercolationSystem.AreaImage,
        PercolationSystem.ValueImage,
    ]

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
            color: Qt.lighter(playerTeamColor, 1.9)
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
                if(currentImageTypeIndex + 1 >= imageTypes.length) {
                    currentImageTypeIndex = 0
                } else {
                    currentImageTypeIndex += 1
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
        anchors{
            top: returnToMainMenuButton.bottom
            left: parent.left
            right: parent.right
            margins: 16
        }
        text: {
            var result = "We are team " + playerTeamName + "\n";
            for(var i in teamAreas) {
                result += "Team " + i + ": " + teamAreas[i] + "\n";
            }
            return result;
        }
    }
}
