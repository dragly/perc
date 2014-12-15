import QtQuick 2.0

Item {
    property list<Interaction> interactions: [
        Interaction {
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
        ,
        Interaction {
            entityType1: "Soldier"
            entityType2: "Soldier"
            onInteract: {
                var soldier1 = entity1
                var soldier2 = entity2
                if(soldier1.team !== soldier2.team) {
                    soldier1.healthPoints -= 20.0
                    soldier2.healthPoints -= 20.0
                }
            }
        }
        ,
        Interaction {
            entityType1: "Soldier"
            entityType2: "DirectionWalker"
            onInteract: {
                var soldier = entity1
                var walker = entity2
                if(soldier.team !== walker.team) {
                    walker.kill()
                }
            }
        }
        ,
        Interaction {
            entityType1: "Soldier"
            entityType2: "RandomWalker"
            onInteract: {
                var soldier = entity1
                var walker = entity2
                if(soldier.team !== walker.team) {
                    walker.kill()
                }
            }
        }
        ,
        Interaction {
            entityType1: "Hero"
            entityType2: "Soldier"
            onInteract: {
                var hero = entity1
                var soldier = entity2
                if(hero.team !== soldier.team) {
                    soldier.kill()
                }
            }
        }
    ]

    function interact(entity1, entity2) {
        var xDiff = entity1.col - entity2.col
        var yDiff = entity1.row - entity2.row
        var distance = Math.abs(xDiff) + Math.abs(yDiff)
        for(var k in interactions) {
            var interaction = interactions[k]
            if(distance < interaction.minimumDistance || distance > interaction.maximumDistance) {
                continue
            }

            if(interaction.entityType1 === entity1.objectName &&
                    interaction.entityType2 === entity2.objectName) {
                interaction.interact(entity1, entity2, distance)
            } else if(interaction.entityType2 === entity1.objectName &&
                      interaction.entityType1 === entity2.objectName) {
                interaction.interact(entity2, entity1, distance)
            }
        }
    }
}
