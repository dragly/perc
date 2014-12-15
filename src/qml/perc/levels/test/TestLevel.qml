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
    property EntityBase decoy: null

    onClicked: {
        if(hero !== null) {
            var site = mapPointToSite(mouse)
            decoy.row = site.row
            decoy.col = site.col
        }
    }

    onRestart: {
        var properties
        for(var i = 0; i < 10; i++) {
            var site = Logic.randomSiteOnLargestCluster(percolationSystem)
            properties = {
                team: playerTeam,
                row: site.row,
                col: site.col
            }
            entityManager.createEntityFromUrl("walkers/DirectionWalker.qml", properties);
        }

        var mainSoldierSite = Logic.randomSiteOnLargestCluster(percolationSystem)
        properties = {
            team: playerTeam,
            row: mainSoldierSite.row,
            col: mainSoldierSite.col
        }
        hero = entityManager.createEntityFromUrl("walkers/Hero.qml", properties)

        properties = {
            row: mainSoldierSite.row,
            col: mainSoldierSite.col,
            blocking: false
        }
        decoy = entityManager.createEntityFromUrl("EntityBase.qml", properties)
        hero.target = decoy

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
