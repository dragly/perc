import QtQuick 2.0
import "../.."
import "../../logic.js" as Logic
import "../../spawns"

GameView {
    id: gameViewRoot

    nRows: 50
    nCols: 50
    occupationTreshold: 0.6

    property Spawn playerSpawn: null
    property Spawn enemySpawn: null

    function spawnWalker(spawn, properties) {
        properties.row = spawn.row
        properties.col = spawn.col
        properties.team = spawn.team
        if(properties.team === playerTeam) {
            properties.target = enemySpawn
        } else {
            properties.target = playerSpawn
        }

        var walker = entityManager.createEntityFromUrl("walkers/Soldier.qml", properties)
    }

    onRestart: {
        console.log("Spawn")
        var playerSpawnSite = Logic.randomSiteOnLargestCluster(percolationSystem)
        var properties = {
            team: playerTeam,
            row: playerSpawnSite.row,
            col: playerSpawnSite.col,
            interval: 1000
        }
        playerSpawn = entityManager.createEntityFromUrl("spawns/Spawn.qml", properties)
        var enemySpawnSite = Logic.randomSiteOnLargestCluster(percolationSystem)
        properties = {
            team: enemyTeam,
            row: enemySpawnSite.row,
            col: enemySpawnSite.col,
            interval: 900
        }
        enemySpawn = entityManager.createEntityFromUrl("spawns/Spawn.qml", properties)

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

    winObjectives: [
        Objective {
            onTest: {
                if(enemySpawn.healthPoints <= 0) {
                    completed = true
                }
            }
        }
    ]

    failObjectives: [
        Objective {
            onTest: {
                if(playerSpawn.healthPoints <= 0) {
                    completed = true
                }
            }
        }
    ]
}
