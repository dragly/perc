import QtQuick 2.0
import "../.."
import "../../logic.js" as Logic
import "../../spawns"

GameView {
    id: gameViewRoot

    nRows: 20
    nCols: 20
    occupationTreshold: 0.7
}
