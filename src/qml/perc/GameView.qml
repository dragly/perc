import QtQuick 2.0

Rectangle {
    id: viewRoot
    width: 100
    height: 62
    color: "red"

    GameScene {
        id: gameScene
        objectName: "gameScene"
        imageType: gameMenu.imageType

        onSelectedObjectsChanged: {
            if(selectedObjects.length > 0) {
                for(var i in selectedObjects) {
                    gameObjectInfo.text = selectedObjects[i].informationText
                }
            } else {
                gameObjectInfo.text = "Nothing selected"
            }
        }
    }

    MouseArea {
        property int prevX: -1
        property int prevY: -1
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onWheel: {
            //            var realGameSceneX = gameScene.scaleOriginX
            var currentScaleOrigin = mapFromItem(gameScene, gameScene.scaleOriginX, gameScene.scaleOriginY)
            var relativeMouse = mapToItem(gameScene, wheel.x, wheel.y)
            //            gameScene.x += wheel.x - currentScaleOrigin.x
            //            gameScene.y += wheel.y - currentScaleOrigin.y
            gameScene.scaleOriginX = relativeMouse.x
            gameScene.scaleOriginY = relativeMouse.y
            if(wheel.angleDelta.y > 0) {
                gameScene.targetScale *= 1.5
            } else if(wheel.angleDelta.y < 0) {
                gameScene.targetScale /= 1.5
            }
            var newPosition = mapFromItem(gameScene, relativeMouse.x, relativeMouse.y)
            gameScene.x += wheel.x - newPosition.x
            gameScene.y += wheel.y - newPosition.y
        }

        onPositionChanged: {
            if(prevX > -1 && prevY > -1) {
                gameScene.x += mouse.x - prevX
                gameScene.y += mouse.y - prevY
            }
            prevX = mouse.x
            prevY = mouse.y
        }

        onReleased: {
            prevX = -1
            prevY = -1
        }

        onExited: {
            prevX = -1
            prevY = -1
        }
    }

    GameMenu {
        id: gameMenu
    }

    Rectangle {
        id: gameObjectInfo
        property alias text: gameObjectInfoText.text
        anchors.right: parent.right
        anchors.top: parent.top
        width: parent.width * 0.2
        height: parent.height * 0.1
        Text {
            id: gameObjectInfoText
            anchors.centerIn: parent
            text: "Nothing selected"
            font.pixelSize: parent.height * 0.2
        }
    }
}
