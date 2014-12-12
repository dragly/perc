import QtQuick 2.0

Item {
    property var interactions: [interaction1]

    function interact(entity1, entity2) {
        for(var k in interactions) {
            var interaction = interactions[k]
            if(interaction.entityType1 === entity1.objectName &&
                    interaction.entityType2 === entity2.objectName) {
                interaction.interact(entity1, entity2)
            } else if(interaction.entityType2 === entity1.objectName &&
                      interaction.entityType1 === entity2.objectName) {
                interaction.interact(entity2, entity1)
            }
        }
    }
    Interaction {
        id: interaction1
        entityType1: "Soldier"
        entityType2: "Spawn"
        onInteract: {
            var soldier = entity1
            var spawn = entity2
            if(soldier.team !== spawn.team) {
                spawn.healthPoints -= 1
            }
        }
    }
}
