import QtQuick 2.0

Item {
    property var gameView: null
    property GameScene gameScene: null
    property var componentUrls: []
    property var components: []
    property var entities: []

    function addInteraction(interaction) {
        interactions.push(interaction)
    }

    function createEntityFromUrl(url, properties) {
        if(properties === undefined) {
            properties = {}
        }

        properties.gameView = gameView

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
        return entity
    }

    function advance(currentUpdateTime) {
        for(var i = 0; i < entities.length; i++) {
            var entity1 = entities[i]
            for(var j = i + 1; j < entities.length; j++) {
                var entity2 = entities[j]
                if(entity1.row !== entity2.row || entity1.col !== entity2.col) {
                    continue
                }
                interactionManager.interact(entity1, entity2)
            }
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
