import QtQuick 2.0

Rectangle {
    width: 640
    height: 480
    property alias text: myText.text

    GameView {
        id: gameView
        anchors.fill: parent
        color: "grey"
    }

    Text {
        id: myText
        text: "Banana"
    }
}
