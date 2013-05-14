import QtQuick 2.0
import "../.."
import "../../logic.js" as Logic

GameView {
    id: gameViewRoot

    nRows: 500
    nCols: 500

    onRestart: {
        for (var i = 0; i < 50; i++) {
            Logic.createRandomWalker("raise", playerTeam)
            Logic.createRandomWalker("lower", playerTeam)
            Logic.createDirectionWalker("left", enemyTeam)
            Logic.createDirectionWalker("right", enemyTeam)
        }

        for(var i = 0; i < 50; i++) {
            Logic.createPressureSource()
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
