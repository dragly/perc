import QtQuick 2.0
import QtGraphicalEffects 1.0
import org.dragly.perc 1.0

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
    property alias traversability: percolationSystem.traversability
    readonly property alias percolationSystem: percolationSystem
    readonly property alias entityManager: entityManager
//    property alias pressureSources: percolationSystem.pressureSources
    property Team playerTeam: playerTeamInternal
    property list<Team> otherTeams
    property var selectedObjects: []

    property list<Objective> failObjectives
    property list<Objective> winObjectives

    width: 100
    height: 62

    state: "paused"

    function failGame() {
        failGameDialog.visible = true
    }

    function winGame() {
        winGameDialog.visible = true
    }

    function requestSelection(object) {
        for(var i in entityManager.entities) {
            var other = entityManager.entities[i]
            other.selected = false
        }
        var objects = []
        objects.push(object)
        object.selected = true

        selectedObjects = objects
    }

    onPause: {
        state = "paused"
    }

    onResume: {
        state = "running"
    }

    onRestart: {
        for(var i in winObjectives) {
            var objective = winObjectives[i]
            objective.completed = false
        }
        for(var i in failObjectives) {
            var objective = failObjectives[i]
            objective.completed = false
        }

        console.log("Restarting!")
        winGameDialog.visible = false
        failGameDialog.visible = false

        entityManager.clear()
        percolationSystem.pressureSources = []
        percolationSystem.initialize()
        occupationGrid.initialize()
        resume()

        var newScale = 0.2
        gameScene.scaleOriginX = 0.0
        gameScene.scaleOriginY = 0.0
        gameScene.currentScale = newScale
        var gameSceneRect = gameViewRoot.mapFromItem(gameScene, 0, 0, gameScene.width, gameScene.height)
        gameScene.x = gameViewRoot.width / 2 - gameSceneRect.width / 2
        gameScene.y = gameViewRoot.height / 2 - gameSceneRect.height / 2
        gameScene.targetScale = newScale
    }

    onWidthChanged: {
//        percolationSystemShader.updateSourceRect()
    }

    onHeightChanged: {
//        percolationSystemShader.updateSourceRect()
    }

    Component.onCompleted: {
    }

    Team {
        id: playerTeamInternal
        isPlayer: true
        name: "player"
        color: "#6a3d9a"
        lightColor: "#cab2d6"
    }

    Rectangle {
        id: backgroundRect
        RadialGradient {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#9ecae1" }
                GradientStop { position: 1.0; color: "#6baed6" }
            }
        }
        anchors.fill: parent
    }

    MainGrid {
        id: mainGrid
        columnCount: percolationSystem.nCols
        rowCount: percolationSystem.nRows
    }

    OccupationGrid {
        id: occupationGrid
        mainGrid: mainGrid
    }

    PercolationSystem {
        id: percolationSystem
        width: nCols
        height: nRows
        nRows: 10
        nCols: 10
        traversability: 0.55
        imageType: constructionMenu.imageType
        smooth: false
    }

    GameScene {
        id: gameScene

        width: percolationSystem.nCols * Defaults.GRID_SIZE
        height: percolationSystem.nRows * Defaults.GRID_SIZE

        objectName: "gameScene"
        targetScale: 0.2
        percolationSystem: percolationSystem

        onCurrentScaleChanged: {
            ensureWithinBounds()
        }

        function ensureWithinBounds() {
            return
            var gameSceneRect = gameViewRoot.mapFromItem(gameScene, 0, 0, gameScene.width, gameScene.height)
            var xDiffRight = gameSceneRect.x + gameSceneRect.width - gameViewRoot.width
            var yDiffBottom = gameSceneRect.y + gameSceneRect.height - gameViewRoot.height
            if(gameSceneRect.width > gameViewRoot.width) {
                if(gameSceneRect.x > 0) {
                    gameScene.x -= gameSceneRect.x
                }
                if(xDiffRight < 0) {
                    gameScene.x -= xDiffRight
                }
            } else {
                if(gameSceneRect.x < 0) {
                    gameScene.x -= gameSceneRect.x
                }
                if(xDiffRight > 0) {
                    gameScene.x -= xDiffRight
                }
            }

            if(gameSceneRect.height > gameViewRoot.height) {
                if(gameSceneRect.y > 0) {
                    gameScene.y -= gameSceneRect.y
                }
                if(yDiffBottom < 0) {
                    gameScene.y -= yDiffBottom
                }
            } else {
                if(gameSceneRect.y < 0) {
                    gameScene.y -= gameSceneRect.y
                }
                if(yDiffBottom > 0) {
                    gameScene.y -= yDiffBottom
                }
            }
        }
    }

    EntityManager {
        id: entityManager
        gameScene: gameScene
        gameView: gameViewRoot
        percolationSystem: percolationSystem
        occupationGrid: occupationGrid
        onKilledEntity: {
            var newSelection = selectedObjects
            var index = gameViewRoot.selectedObjects.indexOf(entity)
            if(index !== -1) {
                gameViewRoot.selectedObjects.splice(index, 1)
            }
            selectedObjects = newSelection
        }
    }

    MouseArea {
        id: mainViewMouseArea
        property bool isDragging: false
        property bool isSelecting: false
        property real pressedTime: Date.now()
        property double prevX: 0
        property double prevY: 0
        property var pressedObject: null
        property point pressedPoint
        property point previousPoint
//        propagateComposedEvents: true
//        hoverEnabled: true
        anchors.fill: parent
//        drag.target: gameScene

        onPressed: {
            pressedTime = Date.now()
            pressedObject = null
            previousPoint = Qt.point(mouse.x, mouse.y)
            pressedPoint = Qt.point(mouse.x, mouse.y)

            if(mouse.buttons & Qt.LeftButton && mouse.modifiers & Qt.ShiftModifier) {
                console.log("Started selection")
                isSelecting = true
            } else if(mouse.buttons & Qt.LeftButton) {
                for(var i in entityManager.entities) {
                    var entity = entityManager.entities[i]
                    var entityPos = gameViewRoot.mapFromItem(gameScene, entity.x, entity.y)
                    if(entityPos.x < mouse.x && entityPos.x + entity.width > mouse.x
                            && entityPos.y < mouse.y && entityPos.y + entity.height > mouse.y) {
                        pressedObject = entity
                        break
                    }
                }

                isDragging = true
                prevX = mouse.x
                prevY = mouse.y
            }
        }

        onPositionChanged: {
            var relativeMouse = mapToItem(gameScene, mouse.x, mouse.y)

            // Selection
            if(isSelecting && mouse.buttons & Qt.LeftButton && mouse.modifiers & Qt.ShiftModifier) {
                if(mouse.x > pressedPoint.x) {
                    selectionRectangle.x = pressedPoint.x
                    selectionRectangle.width = mouse.x - pressedPoint.x
                } else {
                    selectionRectangle.x = mouse.x
                    selectionRectangle.width = pressedPoint.x - mouse.x
                }
                if(mouse.y > pressedPoint.y) {
                    selectionRectangle.y = pressedPoint.y
                    selectionRectangle.height = mouse.y - pressedPoint.y
                } else {
                    selectionRectangle.y = mouse.y
                    selectionRectangle.height = pressedPoint.y - mouse.y
                }
            }

            // Dragging
            if(isDragging && mouse.buttons & Qt.LeftButton) {
                gameScene.x += mouse.x - prevX
                gameScene.y += mouse.y - prevY
                gameScene.ensureWithinBounds()
            }
            prevX = mouse.x
            prevY = mouse.y
        }

        function uniqueArray(a) {
            return a.filter(function(item, pos, self) {
                return self.indexOf(item) == pos;
            })
        }

        onReleased: {
            var currentTime = Date.now()
            var timeDiff = currentTime - pressedTime
            //  && mouse.buttons & Qt.LeftButton && mouse.modifiers & Qt.ShiftModifier
            if(isSelecting) {
                var newSelection;
                if(mouse.modifiers & Qt.ShiftModifier) {
                    newSelection = selectedObjects
                } else {
                    newSelection = []
                }
                for(var i in entityManager.entities) {
                    var entity = entityManager.entities[i]
                    var entityPos = gameViewRoot.mapFromItem(gameScene, entity.x, entity.y)
                    console.log(entityPos.x, entityPos.y)
                    var rect = selectionRectangle
                    console.log(selectionRectangle.x, selectionRectangle.y)
                    if(entityPos.x > rect.x && entityPos.x < rect.x + rect.width
                            && entityPos.y > rect.y && entityPos.y < rect.y + rect.height) {
                        newSelection.push(entity)
                    } else {
                        entity.selected = false
                    }
                }
                for(var i in newSelection) {
                    var entity = newSelection[i]
                    entity.selected = true
                }
                newSelection = uniqueArray(newSelection)
                selectedObjects = newSelection
                isSelecting = false
            }

            if(!isSelecting && !(mouse.modifiers & Qt.ShiftModifier)) {
                var deltaX = mouse.x - prevX
                var deltaY = mouse.y - prevY
                if(Math.sqrt(deltaX*deltaX + deltaY*deltaY) < 10 && timeDiff < 300) {
                    for(var i in selectedObjects) {
                        var entity = selectedObjects[i]
                        if(entity) {
                            entity.selected = false
                        }
                    }

                    selectedObjects = []
                }
            }

            var deltaX = mouse.x - pressedPoint.x
            var deltaY = mouse.y - pressedPoint.y

            if(pressedObject && Math.sqrt(deltaX*deltaX + deltaY*deltaY) < 10 && timeDiff < 300) {
                pressedObject.selected = true
                selectedObjects = [pressedObject]
            }

            isDragging = false
            isSelecting = false
            selectionRectangle.width = 1
            selectionRectangle.height = 1
        }

        onWheel: {
            var relativeMouse = mapToItem(gameScene, wheel.x, wheel.y)
            gameScene.scaleOriginX = relativeMouse.x
            gameScene.scaleOriginY = relativeMouse.y
            if(wheel.angleDelta.y > 0) {
                gameScene.targetScale *= 1.3
            } else if(wheel.angleDelta.y < 0) {
                gameScene.targetScale /= 1.3
            }
            var newPosition = mapFromItem(gameScene, relativeMouse.x, relativeMouse.y)
            gameScene.x += wheel.x - newPosition.x
            gameScene.y += wheel.y - newPosition.y
        }
    }

    Rectangle {
        id: selectionRectangle
        border.width: 1
        border.color: "white"
        color: Qt.rgba(1,1,1,0.4)
        width: 0
        height: 0
        visible: mainViewMouseArea.isSelecting
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

    Rectangle {
        id: winGameDialog
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.8
        visible: false
        Text {
            anchors.centerIn: parent
            text: "You win!"
        }
    }

    Rectangle {
        id: failGameDialog
        anchors.centerIn: parent
        width: parent.width * 0.8
        height: parent.height * 0.8
        visible: false
        Text {
            anchors.centerIn: parent
            text: "You fail!"
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
        selectedObjects: gameViewRoot.selectedObjects
    }

    states: [
        State {
            name: "paused"
            PropertyChanges {
                target: inGameMenu
                state: "visible"
            }
        },
        State {
            name: "running"
            PropertyChanges {
                target: inGameMenu
                state: "hidden"
            }
        }
    ]

    InGameMenu {
        id: inGameMenu
        opacity: 0
        enabled: false

        onContinueClicked: {
            resume()
        }

        onRestartClicked: {
            restart()
        }

        onExitToMainMenuClicked: {
            exitToMainMenu()
        }
    }

    Timer {
        id: advanceTimer
        property int triggers: 0
        running: (state === "running")
        interval: 1000 / 60 // hoping for 60 FPS
        repeat: true
        onTriggered: {
            var currentTime = Date.now()
            advance(currentTime)
            if(percolationSystem.tryLockUpdates()) {
                entityManager.advance(currentTime)
                var fail = false
                for(var i in failObjectives) {
                    var failObjective = failObjectives[i]
                    failObjective.test()
                    fail = fail || failObjective.completed
                }
                var win = false
                for(var i in winObjectives) {
                    var winObjective = winObjectives[i]
                    winObjective.test()
                    win = win || winObjective.completed
                }

                if(win) {
                    console.log("Game won")
                    winGame()
                } else if(fail) {
                    console.log("Game failed")
                    failGame()
                }

                percolationSystem.unlockUpdates()
                percolationSystem.requestRecalculation()
            }
        }
    }
}
