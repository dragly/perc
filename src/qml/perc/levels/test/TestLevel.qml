import QtQuick 2.0
import "../.."
import "../../logic.js" as Logic

GameView {
    id: gameViewRoot

    nRows: 500
    nCols: 500

    onRestart: {
        for (var i = 0; i < 50; i++) {
            var site = Logic.randomSite(percolationSystem)
            var properties = {
                type: "lower",
                team: playerTeam,
                row: site.row,
                col: site.col
//                lightSource: gameScene.lightSource
            }
            entityManager.createEntityFromUrl("walkers/RandomWalker.qml", properties);
        }

        for(var i = 0; i < 50; i++) {
            var site = Logic.randomSite(percolationSystem)
            var properties = {
                pressure: 1,
                row: site.row,
                col: site.col
            }
            entityManager.createEntityFromUrl("sources/PressureSource.qml", properties);
        }

        var plane = entityManager.createEntityFromUrl("planes/FighterPlane.qml")
    }

    otherTeams: [
        Team {
            id: enemyTeam
            name: "enemy"
            color: "orange"
        }
    ]
}
