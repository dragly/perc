import QtQuick 2.0

Item {
    property bool isPlayer: false
    property color color: "red"
    property color lightColor: "pink"
    property string name: "unnamed"
    property real energy: 0

    width: 100
    height: 62

    function addEnergy(amount) {
        energy += amount
    }
}
