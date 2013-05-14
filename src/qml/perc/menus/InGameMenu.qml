import QtQuick 2.0

Item {
    id: inGameMenuRoot

    signal continueClicked
    signal exitToMainMenuClicked

    property double defaultMargin: width * 0.01

    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        color: "black"
        opacity: 0.5
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: parent.width * 0.1
        color: "white"

        Column {
            anchors.fill: parent
            anchors.margins: inGameMenuRoot.defaultMargin
            spacing: inGameMenuRoot.defaultMargin
            Rectangle {
                id: continueButton
                width: parent.width
                height: 50

                color: "blue"
                Text {
                    anchors.centerIn: parent
                    text: "Continue"
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        continueClicked()
                    }
                }
            }

            Rectangle {
                id: exitButton
                width: parent.width
                height: 50

                color: "blue"
                Text {
                    anchors.centerIn: parent
                    text: "Exit to main menu"
                    color: "white"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        exitToMainMenuClicked()
                    }
                }
            }
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 200
        }
    }
}
