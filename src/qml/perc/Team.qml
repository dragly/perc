import QtQuick 2.0

import Perc 1.0

PercObject {
    id: root
    property bool isPlayer: false
    property color color: "red"
    property string name: "unnamed"
    property real energy: 0
    property int teamId: 0
    property bool toBeDeleted: false

    objectName: "Team"
    persistentProperties: QtObject {
        id: props
        property alias name: root.name
        property alias teamId: root.teamId
        property string color: root.color
    }
    Binding {
        target: root
        property: "color"
        value: props.color
    }

    width: 100
    height: 62

    function addEnergy(amount) {
        energy += amount
    }
}
