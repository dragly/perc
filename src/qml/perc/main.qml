import QtQuick 2.0

import "."

Rectangle {
    id: gameRoot

    width: 1280
    height: 720

    color: "grey"

    state: "main"

    function testMe() {
        state = "main"
    }

    Loader {
        id: levelLoader
        anchors.fill: parent
        onLoaded: {
            item.returnToMainMenuClicked.connect(gameRoot.testMe)
        }
    }

    Item {
        id: mainMenu
        opacity: 0

        anchors.fill: parent

        Rectangle {
            color: "white"
            opacity: 0.5
            anchors {
                fill: parent
            }
        }

        Rectangle {
            color: "white"
            anchors {
                fill: parent
                margins: parent.width * 0.1
            }
        }

        Rectangle {
            color: "blue"
            width: 100
            height: 100
            Text {
                text: "Load level"
                color: "white"
                anchors.centerIn: parent
            }
            anchors.centerIn: parent
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    levelLoader.source = "levels/test/TestLevel.qml"
                    gameRoot.state = "game"
                }
            }
        }
    }

    states: [
        State {
            name: "main"
            PropertyChanges {
                target: mainMenu
                opacity: 1
            }
        },
        State {
            name: "game"
        }

    ]
}
