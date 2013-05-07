import QtQuick 2.0

import "."

Rectangle {
    width: 640
    height: 480

    GameView {
        id: gameView
        anchors.fill: parent
        color: "grey"
    }
}
