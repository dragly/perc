import QtQuick 2.0
import "../.."
import "../../logic.js" as Logic
import "../../spawns"

GameView {
    id: gameViewRoot

    nRows: 100
    nCols: 100
    occupationTreshold: 0.7
}
