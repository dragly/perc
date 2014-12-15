import QtQuick 2.0
import "../.."
import "../../logic.js" as Logic
import "../../spawns"

GameView {
    id: levelRoot

    nRows: 50
    nCols: 70
    traversability: 0.6

    property Spawn playerSpawn: null
    property Spawn enemySpawn: null

    function spawnWalker(spawn, properties) {
        properties.row = spawn.row
        properties.col = spawn.col
        properties.team = spawn.team
        if(properties.team === playerTeam) {
            properties.healthPoints = 120
            properties.target = enemySpawn
        } else {
            properties.target = playerSpawn
        }

        var walker = entityManager.createEntityFromUrl("walkers/Soldier.qml", properties)
    }

    onRestart: {
        for(var i = 0; i < 10; i++) {
            var site = Logic.randomSiteOnLargestCluster(percolationSystem)
            var properties = {
                team: playerTeam,
                row: site.row,
                col: site.col
            }
            entityManager.createEntityFromUrl("walkers/DirectionWalker.qml", properties);
        }
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
