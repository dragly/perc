import QtQuick 2.0
import "../.."
import "../../logic.js" as Logic
import "../../spawns"

GameView {
    id: gameViewRoot

    nRows: 50
    nCols: 50
    occupationTreshold: 0.6
}
