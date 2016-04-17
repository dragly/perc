import QtQuick 2.0

Item {
    id: root
    property bool isPlayer: false
    property color color: "red"
    property color lightColor: "pink"
    property string name: "unnamed"
    property real energy: 0
    property int teamId: 0

    property QtObject properties: QtObject {
        property alias name: root.name
        property string color: root.color
        property alias teamId: root.teamId
    }

    width: 100
    height: 62

    function addEnergy(amount) {
        energy += amount
    }
}
