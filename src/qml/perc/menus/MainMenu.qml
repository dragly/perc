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
                selectedLevel("test/TestLevel.qml")
            }
        }
    }
}
