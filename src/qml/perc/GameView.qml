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
        property real targetScale: scale
        readonly property alias currentScale: scaleTransform.xScale
        property alias scaleOriginX: scaleTransform.origin.x
        property alias scaleOriginY: scaleTransform.origin.y

        Rectangle {
            id: currentOrigin
            x: scaleTransform.origin.x
            y: scaleTransform.origin.y
            width: 2
            height: 2
            color: "yellow"
        }

        transform: [
            Scale {
                id: scaleTransform

                property int scaleDuration: 200

                Behavior on xScale {
                    NumberAnimation {
                        duration: scaleTransform.scaleDuration
                        easing.type: Easing.OutQuad
                    }
                }

                Behavior on yScale {
                    NumberAnimation {
                        duration: scaleTransform.scaleDuration
                        easing.type: Easing.OutQuad
                    }
                }
            },
            Translate {
                id: positionTransform
            }
        ]

        onTargetScaleChanged: {
            scaleTransform.xScale = targetScale
            scaleTransform.yScale = targetScale
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
}
