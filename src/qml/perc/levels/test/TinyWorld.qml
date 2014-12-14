import QtQuick 2.0
import "../.."
import "../../logic.js" as Logic

GameView {
    id: levelRoot

    nRows: 50
    nCols: 50
    occupationTreshold: 0.6

//    playerTeam.energy: 10

    onRestart: {
        console.log("Restart")
        var site = Logic.randomSite(percolationSystem)
        var properties = {
            pressure: 1,
            row: site.row,
            col: site.col
        }
        entityManager.createEntityFromUrl("sources/PressureSource.qml", properties);


        for(var i = 0; i < 10; i++) {
            site = Logic.randomSite(percolationSystem)
            properties = {
                type: "lower",
                team: playerTeam,
                row: site.row,
                col: site.col,
                lightSource: gameScene.lightSource
            }
            entityManager.createEntityFromUrl("walkers/RandomWalker.qml", properties);
        }
    }

    otherTeams: [
        Team {
            id: enemyTeam
            name: "enemy"
            color: "orange"
        }
    ]
}
