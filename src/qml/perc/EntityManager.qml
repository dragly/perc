import QtQuick 2.0

Item {
    property var componentUrls: []
    property var components: []
    property var entities: []

    function createEntityFromUrl(url, properties) {
        if(properties === undefined) {
            properties = {}
        }

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
        var entity = component.createObject(parent, properties)
        if(entity === null) {
            console.log("Could not create entity!")
            console.log(component.errorString())
        }

        entities.push(entity)
        entity.requestSelection.connect(gameScene.requestSelection)
        return entity
    }
}
