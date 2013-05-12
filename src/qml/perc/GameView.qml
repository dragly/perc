import QtQuick 2.0
import com.dragly.perc 1.0
import "defaults.js" as Defaults

Rectangle {
    id: viewRoot
    width: 100
    height: 62
    color: "red"

    Component.onCompleted: {
        percolationSystemShader.updateSourceRect()
    }

    PercolationSystem {
        id: percolationSystem
        width: nCols
        height: nRows
        nRows: 500
        nCols: 500
        occupationTreshold: 0.55
        imageType: gameMenu.imageType

        smooth: false
    }

    PercolationSystemShader {
        id: percolationSystemShader
        source: percolationSystem
        lightSource: lightSource

        anchors.fill: parent

        smooth: true
        samples: 16 * Math.sqrt(gameScene.targetScale)

        function updateSourceRect() {
            sourceRect = Qt.rect(- (mapFromItem(gameScene, 0,0).x) / (Defaults.GRID_SIZE * gameScene.targetScale),
                                -(mapFromItem(gameScene, 0,0).y) / (Defaults.GRID_SIZE * gameScene.targetScale),
                                viewRoot.width / (Defaults.GRID_SIZE * gameScene.targetScale),
                                viewRoot.height / (Defaults.GRID_SIZE * gameScene.targetScale))
        }

//        transform: Scale {
//            xScale: Defaults.GRID_SIZE
//            yScale: Defaults.GRID_SIZE
//        }
    }

    GameScene {
        id: gameScene
        objectName: "gameScene"
        targetScale: 0.1

        onSelectedObjectsChanged: {
            if(selectedObjects.length > 0) {
                for(var i in selectedObjects) {
                    gameObjectInfo.text = selectedObjects[i].informationText
                }
                gameObjectInfo.state = "active"
            } else {
                gameObjectInfo.text = "Nothing selected"
                gameObjectInfo.state = "hidden"
            }
        }

        onCurrentScaleChanged: {
            percolationSystemShader.updateSourceRect()
        }

        smooth: true
    }

    MouseArea {
        id: mainViewMouseArea
        property bool isDragging: false
        property double prevX: 0
        property double prevY: 0
        anchors.fill: parent
        acceptedButtons: Qt.MiddleButton
        onWheel: {
            //            var realGameSceneX = gameScene.scaleOriginX
//            var currentScaleOrigin = mapFromItem(gameScene, gameScene.scaleOriginX, gameScene.scaleOriginY)
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
            percolationSystemShader.updateSourceRect()
        }

        onPressed: {
            console.log("mainViewMouseArea pressed")
            isDragging = true
            prevX = mouse.x
            prevY = mouse.y
        }

        onPositionChanged: {
            if(isDragging) {
                gameScene.x += mouse.x - prevX
                gameScene.y += mouse.y - prevY
                percolationSystemShader.updateSourceRect()
            }
            prevX = mouse.x
            prevY = mouse.y
            isDragging = true
        }

        onReleased: {
            console.log("mainViewMouseArea released")
            isDragging = false
        }

        onExited: {
            isDragging = false
        }
    }

    PinchArea {
        property double previousScale: 1
        anchors.fill: parent
        onPinchStarted: {
            console.log("Pinch started")
            mainViewMouseArea.isDragging = false
            previousScale = pinch.scale
        }

        onPinchUpdated: {
            var relativeMouse = mapToItem(gameScene, viewRoot.width / 2, viewRoot.height / 2)
            gameScene.scaleOriginX = relativeMouse.x
            gameScene.scaleOriginY = relativeMouse.y
            var x = 5 * (pinch.scale - previousScale)
            gameScene.targetScale *= 1 + 0.405 * x + 0.0822 * x * x
            previousScale = pinch.scale
            var newPosition = mapFromItem(gameScene, relativeMouse.x, relativeMouse.y)
            gameScene.x += viewRoot.width / 2 - newPosition.x
            gameScene.y += viewRoot.height / 2 - newPosition.y
        }
        onPinchFinished: {
            console.log("Pinch finished")
        }
    }

    onWidthChanged: {
        console.log(width)
    }

    GameMenu {
        id: gameMenu
    }

    Rectangle {
        id: gameObjectInfo
        property alias text: gameObjectInfoText.text
        anchors.right: parent.right
        anchors.top: parent.top
        state: "active"
        states: [
            State {
                name: "active"
                PropertyChanges {
                    target: gameObjectInfo
                    anchors.topMargin: 0
                }
            },
            State {
                name: "hidden"
                PropertyChanges {
                    target: gameObjectInfo
                    anchors.topMargin: -gameObjectInfo.height * 0.8
                }
            }
        ]

        Behavior on anchors.topMargin {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

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
