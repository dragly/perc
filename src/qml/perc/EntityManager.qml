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

    function addInteraction(interaction) {
        interactions.push(interaction)
    }

    function createEntityFromUrl(url, properties) {
        if(properties === undefined) {
            properties = {}
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
                entity.animationDuration = interval
                entity.move(currentUpdateTime)
            }
            lastTime = currentUpdateTime
        }

        for(var i in entities) {
            var entity = entities[i]
            entity.advance(currentUpdateTime)
        }
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
