import QtQuick 2.0
import "../.."
import "../../logic.js" as Logic
import "../../spawns"

GameView {
    id: gameViewRoot

    rowCount: 100
    columnCount: 100
    occupationTreshold: 0.7
}
