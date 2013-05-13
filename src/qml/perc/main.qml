import QtQuick 2.0

import "."

Rectangle {
    width: 1280
    height: 720

    GameView {
        id: gameView
        anchors.fill: parent
        color: "grey"
    }
}
