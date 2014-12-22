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
    property EntityBase hero: null
    property EntityBase heroTarget: null

    onClicked: {
        if(hero !== null) {
            var site = mapPointToSite(mouse)
            heroTarget.row = site.row
            heroTarget.col = site.col
        }
    }

    onRestart: {
        var properties
        var mainSoldierSite = Logic.randomSiteOnLargestCluster(percolationSystem)
        properties = {
            team: playerTeam,
            row: mainSoldierSite.row,
            col: mainSoldierSite.col
        }
        hero = entityManager.createEntityFromUrl("walkers/Hero.qml", properties)

        properties = {
            row: mainSoldierSite.row,
            col: mainSoldierSite.col
        }
        heroTarget = entityManager.createEntityFromUrl("misc/Empty.qml", properties)
        hero.target = heroTarget

        var playerSpawnSite = Logic.randomSiteOnLargestCluster(percolationSystem)
        properties = {
            team: playerTeam,
            row: playerSpawnSite.row,
            col: playerSpawnSite.col
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

        playerSpawn.defaultProperties = {
            target: enemySpawn
        }
        enemySpawn.defaultProperties = {
            target: playerSpawn
        }
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
