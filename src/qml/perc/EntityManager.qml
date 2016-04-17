import QtQuick 2.0
import org.dragly.perc 1.0

Item {
    id: entityManagerRoot
    property var gameView: null
    property GameScene gameScene: null
    property PercolationSystem percolationSystem: null
    property var componentUrls: []
    property var components: []
    property var entities: []
    property var deadEntities: []
    property double moveInterval: 100
    property double lastTime: Date.now()
    property int nextEntityId: 1
    property int nextTeamId: 1
    property var teams: []
    property int ticksSinceTurn: 0

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

        if(properties.teamId === undefined) {
            properties.teamId = nextTeamId;
            nextTeamId += 1;
        }

        var teamComponent = Qt.createComponent("Team.qml");
        var team = teamComponent.createObject(entityManagerRoot, properties);
        entityManagerRoot.teams.push(team);
        return team;
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
            console.log("Could not create entity!")
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

    function advance(currentUpdateTime) {
        if(ticksSinceTurn > 10) {
            console.log("Turn!");
            for(var i in entities) {
                var entity = entities[i];
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
            }

            ticksSinceTurn = 0;
        }

        // remove dead entities
        for(var i in deadEntities) {
            var deadEntity = deadEntities[i]
            var index = entities.indexOf(deadEntity)
            if(index !== -1) {
                entities.splice(index, 1)
            }
            deadEntity.destroy(100)
        }

        deadEntities = []

        for(var i = 0; i < entities.length; i++) {
            var entity1 = entities[i]
            for(var j = i + 1; j < entities.length; j++) {
                var entity2 = entities[j]
                interactionManager.interact(entity1, entity2)
            }
        }

        var interval = currentUpdateTime - lastTime
        if(interval > moveInterval) {
            for(var i in entities) {
                var entity = entities[i]
                entity.move(currentUpdateTime)
            }
            lastTime = currentUpdateTime
        }

        for(var i in entities) {
            var entity = entities[i]
            entity.advance(currentUpdateTime)
        }

        ticksSinceTurn += 1;
    }

    function clear() {
        for(var i in entities) {
            var entity = entities[i]
            entity.destroy()
        }
        entities = []
    }

    InteractionManager {
        id: interactionManager
    }
}
