import QtQuick 2.0
import "defaults.js" as Defaults

Rectangle {
    id: selectionIndicator

    property var selectedObjects
    //        property double targetWidth: 10 //(mySelectedObject !== null) ? Math.max(mySelectedObject.width + 5, 10 / gameScene.targetScale) : 0
    //        property double targetHeight: 10 //(mySelectedObject !== null) ? Math.max(mySelectedObject.width + 5, 10 / gameScene.targetScale) : 0

    color: "transparent"
    border.color: "white"
    border.width: Math.max(1, 1 / gameScene.targetScale)
//    anchors.centerIn: (selectedObjects.length > 0) ? selectedObjects[0] : parent
    z: 9999
    width: Defaults.GRID_SIZE
    height: Defaults.GRID_SIZE

    onSelectedObjectsChanged: {
        refresh()
        console.log("Selected objects changed!")
    }

    function refresh() {
        if(selectedObjects !== undefined && selectedObjects.length > 0) {
            visible = true
            var xMin = 99999999
            var yMin = 99999999
            var xMax = -99999999
            var yMax = -99999999
            for(var i in selectedObjects) {
                var object = selectedObjects[i]
                xMin = Math.min(xMin, object.x)
                yMin = Math.min(yMin, object.y)
                xMax = Math.max(xMax, object.x + object.width)
                yMax = Math.max(yMax, object.y + object.height)
            }

            x = xMin/* - Defaults.GRID_SIZE * 0.25*/
            y = yMin/* - Defaults.GRID_SIZE * 0.25*/

            width = Math.max(xMax - xMin/* + Defaults.GRID_SIZE * 0.25*/, Defaults.GRID_SIZE / (10 * gameScene.targetScale))
            height = Math.max(yMax - yMin/* + Defaults.GRID_SIZE * 0.25*/, Defaults.GRID_SIZE / (10 * gameScene.targetScale))
        } else {
            visible = false
        }
    }

    SequentialAnimation {
        running: true
        loops: Animation.Infinite
        ColorAnimation { target: selectionIndicator; property: "border.color"; from: "white"; to: "black"; duration: 200; easing.type: Easing.InOutQuad }
        ColorAnimation { target: selectionIndicator; property: "border.color"; from: "black"; to: "white"; duration: 200; easing.type: Easing.InOutQuad }
    }
}
