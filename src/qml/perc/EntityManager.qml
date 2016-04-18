import QtQuick 2.0
import Perc 1.0

Item {
    id: entityManagerRoot
    property var gameView: null
    property GameScene gameScene: null
    property PercolationSystem percolationSystem: null
    property var componentUrls: []
    property var components: []
    property var entities: []
    property var deadEntities: []
    property var deadTeams: []
    property double moveInterval: 100
    property double lastTime: Date.now()
    property int nextEntityId: 1
    property int nextTeamId: 1
    property var colors: ["red", "green", "blue", "yellow", "purple", "pink", "orange", "cyan", "lightblue", "steelblue"]
    property var teams: []

    function addInteraction(interaction) {
        interactions.push(interaction)
    }

    function createTeam(properties) {
        if(properties === undefined) {
            properties = {};
        }

        if(properties.name === undefined) {
            properties.name = "Team " + nextTeamId;
        }

        if(properties.color === undefined) {
            properties.color = colors[nextTeamId % colors.length];
        }

        if(properties.teamId === undefined) {
            properties.teamId = nextTeamId;
            nextTeamId += 1;
        }

        var teamComponent = Qt.createComponent("Team.qml");
        var team = teamComponent.createObject(entityManagerRoot, properties);
        teams.push(team);
        return team;
    }

    function removeTeamsEntities(team) {
        for(var i in entities) {
            var entity = entities[i];
            if(entity.teamId === team.teamId) {
                deadEntities.push(entity)
            }
        }
    }

    function createEntityFromUrl(url, properties) {
        if(properties === undefined) {
            properties = {}
        }

        if(properties.entityId === undefined) {
            properties.entityId = nextEntityId;
            nextEntityId += 1;
        }

        if(properties.team === undefined) {
            console.log("WARNING: Making entity without team!");
        } else {
            properties.teamId = properties.team.teamId;
        }

        properties.gameView = gameView
        properties.entityManager = entityManagerRoot
        properties.percolationSystem = percolationSystem

        var component = null
        for(var i in componentUrls) {
            var componentURL = componentUrls[i]
            if(componentURL === url) {
                component = components[i];
            }
        }

        if(component === null) {
            component = Qt.createComponent(url)
            components.push(component)
            componentUrls.push(url)
        }

        var entity = component.createObject(gameScene, properties)
        if(entity === null) {
            console.log("Could not create entity from url:", url)
            console.log(component.errorString())
        }

        entities.push(entity)
        entity.requestSelection.connect(gameScene.requestSelection)
        entity.killed.connect(killLater)
        return entity
    }

    function killLater(entity) {
        deadEntities.push(entity)
    }

    function removeEntity(entity) {
        entities.splice(entities.indexOf(entity), 1);
        entity.destroy(100);
    }

    function removeTeam(team) {
        teams.splice(teams.indexOf(team), 1);
        team.destroy(100);
    }

    function clearDeadItems() {
        for(var i in deadEntities) {
            var deadEntity = deadEntities[i]
            removeEntity(deadEntity);
        }
        deadEntities = []

        for(var i in deadTeams) {
            var deadTeam = deadTeams[i];
            removeTeam(deadTeam);
        }
        deadTeams = [];
    }

    function advance(currentUpdateTime) {
        clearDeadItems();

        var interval = currentUpdateTime - lastTime
        if(interval > moveInterval) {
            for(var i in entities) {
                var entity = entities[i]
                if(entity.walker) {
                    switch(entity.strategy) {
                    case "move":
                        entity.move(currentUpdateTime)
                        break;
                    case "construct":
                        if(percolationSystem.team(entity.row, entity.col) === entity.team.teamId) {
                            for(var di = -1; di < 2; di++) {
                                for(var dj = -1; dj < 2; dj++) {
                                    var row = entity.row + di;
                                    var column = entity.col + dj;
                                    percolationSystem.teamTag(entity.team.teamId, row, column);
                                    percolationSystem.raiseValue(0.01, row, column);
                                }
                            }
                        }
                        break;
                    case "destruct":
                        for(var di = -1; di < 2; di++) {
                            for(var dj = -1; dj < 2; dj++) {
                                var row = entity.row + di;
                                var column = entity.col + dj;
                                percolationSystem.teamTag(0, row, column);
                                percolationSystem.lowerValue(0.01, row, column);
                            }
                        }
                        var entity1 = entity;
                        for(var j in entities) {
                            var entity2 = entities[j];
                            if(!entity2.walker || entity1 === entity2 || entity1.team === entity2.team) {
                                continue;
                            }
                            var xDiff = entity1.col - entity2.col
                            var yDiff = entity1.row - entity2.row
                            var distance = Math.abs(xDiff) + Math.abs(yDiff)

                            if(distance <= 1) {
                                console.log(entity1, "attacking", entity2)
                                entity2.healthPoints -= 10.0;
                                if(entity2.healthPoints < 0) {
                                    console.log(entity2, "died");
                                    deadEntities.push(entity2);
                                }
                            }
                        }
                        break;
                    default:
                        break;
                    }
                } else if(entity.spawn) {
                    var spawn = entity;
                    if(spawn.spawned) {
                        var properties = {};
                        properties.row = spawn.row
                        properties.col = spawn.col
                        properties.team = spawn.team
                        entityManagerRoot.createEntityFromUrl(spawn.spawnType, properties);
                        spawn.spawned = false;
                    }
                    for(var di = -1; di < 2; di++) {
                        for(var dj = -1; dj < 2; dj++) {
                            var row = spawn.row + di;
                            var column = spawn.col + dj;
                            percolationSystem.teamTag(spawn.team.teamId, row, column);
                            percolationSystem.raiseValue(0.01, row, column);
                        }
                    }
                }

                lastTime = currentUpdateTime
            }

            for(var i in entities) {
                var entity = entities[i]
                entity.advance(currentUpdateTime)
            }
        }
    }

    function clear() {
        for(var i in entities) {
            var entity = entities[i]
            entity.destroy()
        }
        entities = []
    }
}
