import QtQuick 2.0
import com.dragly.perc 1.0

import "hud"

import "defaults.js" as Defaults
import "logic.js" as Logic

Item {
    id: viewRoot

    signal returnToMainMenuClicked
    property double lastUpdateTime: Date.now()
    property real energy: 0

    width: 100
    height: 62

    Component.onCompleted: {
        percolationSystem.initialize()
        for (var i = 0; i < 50; i++) {
            Logic.createRandomWalker("raise")
            Logic.createRandomWalker("lower")
            Logic.createDirectionWalker("left")
            Logic.createDirectionWalker("right")
        }

        for(var i = 0; i < 50; i++) {
            Logic.createPressureSource()
        }

        var plane = entityManager.createEntityFromUrl("planes/FighterPlane.qml")
        percolationSystemShader.updateSourceRect()
    }

    function addEnergy(amount) {
        energy += amount
    }

    onWidthChanged: {
        percolationSystemShader.updateSourceRect()
    }

    onHeightChanged: {
        percolationSystemShader.updateSourceRect()
    }

    Rectangle {
        id: backgroundRect
        color: "grey"
        anchors.fill: parent
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

        anchors.fill: parent

        lightIntensity: 10 * gameScene.targetScale

        smooth: true
        samples: 32 * Math.sqrt(gameScene.targetScale)

        function updateSourceRect() {
            var newRect = viewRoot.mapToItem(gameScene,0,0,viewRoot.width,viewRoot.height)
            sourceRect = Qt.rect(newRect.x / (Defaults.GRID_SIZE),
                                newRect.y / (Defaults.GRID_SIZE),
                                newRect.width / (Defaults.GRID_SIZE),
                                newRect.height / (Defaults.GRID_SIZE))
        }
    }

    GameScene {
        id: gameScene

        width: percolationSystem.width * Defaults.GRID_SIZE
        height: percolationSystem.height * Defaults.GRID_SIZE

        objectName: "gameScene"
        targetScale: 0.1
        percolationSystem: percolationSystem
//        imageType: gameMenu.imageType

        onSelectedObjectsChanged: {
            if(selectedObjects.length > 1) {
                gameObjectInfo.text = "Selected " + selectedObjects.length + " items"
                gameObjectInfo.state = "active"
            } else if(selectedObjects.length > 0) {
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

    EntityManager {
        id: entityManager
        gameScene: gameScene
    }

    Timer {
        property int triggers: 0
        id: advanceTimer
        running: true
        interval: 1000 / 60 // hoping for 60 FPS
        repeat: true
        onTriggered: {
            var currentUpdateTime = Date.now()
            var currentInterval = currentUpdateTime - lastUpdateTime
            if(currentInterval > 200) {
                if(percolationSystem.tryLockUpdates()) {
                    Logic.moveWalkers()
                    Logic.refreshPressures(currentInterval)
                    percolationSystem.unlockUpdates()
                    percolationSystem.requestRecalculation()
                    lastUpdateTime = currentUpdateTime
                }
            }
            //            selectionIndicator.refresh()
        }
    }

    MouseArea {
        id: mainViewMouseArea
        property bool isDragging: false
        property double prevX: 0
        property double prevY: 0
        propagateComposedEvents: true
        hoverEnabled: true
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
//            percolationSystemShader.updateSourceRect()
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
            percolationSystemShader.lightPosX = mouse.x / (viewRoot.width)
            percolationSystemShader.lightPosY = mouse.y / (viewRoot.height)
            var relativeMouse = mapToItem(gameScene, mouse.x, mouse.y)
            gameScene.lightSource.setLightPos(relativeMouse.x, relativeMouse.y)
//            mouse.accepted = false
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

    GameMenu {
        id: gameMenu
        onReturnToMainMenuClicked: {
            viewRoot.returnToMainMenuClicked()
        }
    }

    SelectionMenu {
        id: gameObjectInfo
    }

//    StatsMenu {
//        id: statsMenu
//    }
}
