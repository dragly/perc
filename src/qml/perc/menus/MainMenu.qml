import QtQuick 2.0

Item {
    id: mainMenuRoot

    signal selectedLevel(string levelName)

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

    Row {
        anchors.centerIn: parent
        spacing: parent.width * 0.01
        Rectangle {
            color: "blue"
            width: 100
            height: 100
            Text {
                text: "Test level"
                color: "white"
                anchors.centerIn: parent
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    selectedLevel("test/TestLevel.qml")
                }
            }
        }
        Rectangle {
            color: "blue"
            width: 100
            height: 100
            Text {
                text: "Tiny level"
                color: "white"
                anchors.centerIn: parent
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    selectedLevel("test/TinyWorld.qml")
                }
            }
        }
        Rectangle {
            color: "blue"
            width: 100
            height: 100
            Text {
                text: "Map editor"
                color: "white"
                anchors.centerIn: parent
            }
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    selectedLevel("LevelEditor.qml")
                }
            }
        }
    }
}
