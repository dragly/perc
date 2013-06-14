import QtQuick 2.0
import com.dragly.perc 1.0

import "hud"
import "menus"

import "defaults.js" as Defaults
import "logic.js" as Logic

Item {
    id: gameViewRoot

    signal exitToMainMenu
    signal resume
    signal restart
    signal pause
    signal advance(real currentTime)
    property alias gameScene: gameScene
    property double lastUpdateTime: Date.now()
    property alias nRows: percolationSystem.nRows
    property alias nCols: percolationSystem.nCols
    property alias occupationTreshold: percolationSystem.occupationTreshold
    readonly property alias percolationSystem: percolationSystem
    readonly property alias entityManager: entityManager
//    property alias pressureSources: percolationSystem.pressureSources
    property Team playerTeam: Team{ isPlayer: true; name: "player"}
    property list<Team> otherTeams

    width: 100
    height: 62

    state: "paused"

    onPause: {
        state = "paused"
    }

    onResume: {
        state = "running"
    }

    onRestart: {
        percolationSystem.pressureSources = []
        entityManager.clear()
        percolationSystem.initialize()
        percolationSystemShader.updateSourceRect()
    }

    onWidthChanged: {
        percolationSystemShader.updateSourceRect()
    }

    onHeightChanged: {
        percolationSystemShader.updateSourceRect()
    }

    Component.onCompleted: {
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
        nRows: 10
        nCols: 10
        occupationTreshold: 0.55
        imageType: constructionMenu.imageType
//        pressureSources: pressureSources

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
            var newRect = gameViewRoot.mapToItem(gameScene,0,0,gameViewRoot.width,gameViewRoot.height)
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

        onCurrentScaleChanged: {
            percolationSystemShader.updateSourceRect()
        }

        smooth: true
    }

    Binding {
        id: myBinding
        target: gameObjectInfo
        property: "text"
    }

    EntityManager {
        id: entityManager
        gameScene: gameScene
        gameView: gameViewRoot
    }

    Timer {
        property int triggers: 0
        id: advanceTimer
        running: (state === "running")
        interval: 1000 / 60 // hoping for 60 FPS
        repeat: true
        onTriggered: {
            var currentTime = Date.now()
            advance(currentTime)
            if(percolationSystem.tryLockUpdates()) {
                entityManager.advance(currentTime)
                percolationSystem.unlockUpdates()
                percolationSystem.requestRecalculation()
            }
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
            percolationSystemShader.lightPosX = mouse.x / (gameViewRoot.width)
            percolationSystemShader.lightPosY = mouse.y / (gameViewRoot.height)
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
            var relativeMouse = mapToItem(gameScene, gameViewRoot.width / 2, gameViewRoot.height / 2)
            gameScene.scaleOriginX = relativeMouse.x
            gameScene.scaleOriginY = relativeMouse.y
            var x = 5 * (pinch.scale - previousScale)
            gameScene.targetScale *= 1 + 0.405 * x + 0.0822 * x * x
            previousScale = pinch.scale
            var newPosition = mapFromItem(gameScene, relativeMouse.x, relativeMouse.y)
            gameScene.x += gameViewRoot.width / 2 - newPosition.x
            gameScene.y += gameViewRoot.height / 2 - newPosition.y
        }
        onPinchFinished: {
            console.log("Pinch finished")
        }
    }

    ConstructionMenu {
        id: constructionMenu
        energy: playerTeam.energy
        onPauseClicked: {
            pause()
        }
    }

    SelectionMenu {
        id: gameObjectInfo
        selectedObjects: gameScene.selectedObjects
    }

    states: [
        State {
            name: "paused"
            PropertyChanges {
                target: inGameMenu
                opacity: 1
                enabled: true
            }
        },
        State {
            name: "running"
        }
    ]

    InGameMenu {
        id: inGameMenu
        opacity: 0
        enabled: false

        onContinueClicked: {
            resume()
        }

        onExitToMainMenuClicked: {
            exitToMainMenu()
        }
    }

//    StatsMenu {
//        id: statsMenu
//    }
}
