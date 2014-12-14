import QtQuick 2.0

QtObject {
    property string objectName: "Interaction"
    property string entityType1
    property string entityType2
    property real minimumDistance: 0
    property real maximumDistance: 1.0
    signal interact(var entity1, var entity2)
}
