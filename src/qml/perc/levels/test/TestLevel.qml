import QtQuick 2.0
import "../.."
import "../../logic.js" as Logic
import "../../spawns"

GameView {
    id: gameViewRoot

    rowCount: 5
    columnCount: 5
    occupationTreshold: 1.0
}
