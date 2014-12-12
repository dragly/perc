import QtQuick 2.0
import "../.."
import "../../logic.js" as Logic

GameView {
    id: gameViewRoot

    nRows: 5
    nCols: 5
    occupationTreshold: 0.8

    function spawnWalker(spawn, properties) {
        properties.row = spawn.row
        properties.col = spawn.col
        properties.team = spawn.team
        properties.type = "lower"
        var walker = entityManager.createEntityFromUrl("walkers/Soldier.qml", properties)
    }

    onRestart: {
        var playerSpawnSite = Logic.randomSite(percolationSystem)
        var properties = {
            team: playerTeam,
            row: playerSpawnSite.row,
            col: playerSpawnSite.col
        }
        var playerSpawn = entityManager.createEntityFromUrl("spawns/Spawn.qml", properties)
        var enemySpawnSite = Logic.randomSite(percolationSystem)
        properties = {
            team: enemyTeam,
            row: enemySpawnSite.row,
            col: enemySpawnSite.col
        }
        var enemySpawn = entityManager.createEntityFromUrl("spawns/Spawn.qml", properties)

        playerSpawn.spawnedWalker.connect(spawnWalker)
        enemySpawn.spawnedWalker.connect(spawnWalker)
    }

    otherTeams: [
        Team {
            id: enemyTeam
            name: "enemy"
            color: "orange"
        }
    ]
}
