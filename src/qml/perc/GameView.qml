import QtQuick 2.0
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
        color: "grey"
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

        ShaderEffectSource {
            id: shaderEffectSource
            sourceItem: percolationSystem
            hideSource: true
            width: nCols * Defaults.GRID_SIZE
            height: nRows * Defaults.GRID_SIZE
            mipmap: false
            smooth: false
        }

        ShaderEffect {
            width: nCols * Defaults.GRID_SIZE
            height: nRows * Defaults.GRID_SIZE
            property variant src: shaderEffectSource

            smooth: true
            fragmentShader: "
                varying highp vec2 qt_TexCoord0;
                uniform sampler2D src;
                float threshold(in float thr1, in float thr2 , in float val) {
                    if (val < thr1) {return 0.0;}
                    if (val > thr2) {return 1.0;}
                    return val;
                }

                // averaged pixel intensity from 3 color channels
                float avg_intensity(in vec4 pix) {
                    return (pix.r + pix.g + pix.b)/3.;
                }

                vec4 get_pixel(in vec2 coords, in float dx, in float dy) {
                    return texture2D(src, coords + vec2(dx, dy));
                }

                // returns pixel color
                float IsEdge(in vec2 coords){
                    float dxtex = 1.0 / 1024.0 /*image width*/;
                    float dytex = 1.0 / 1024.0 /*image height*/;
                    float pix[9];
                    int k = -1;
                    float delta;

                    // read neighboring pixel intensities
                    for (int i=-1; i<2; i++) {
                        for(int j=-1; j<2; j++) {
                            k++;
                            pix[k] = avg_intensity(get_pixel(coords,float(i)*dxtex, float(j)*dytex));
                        }
                    }

                    // average color differences around neighboring pixels
                    delta = 0.25*(abs(pix[1]-pix[7])+
                            abs(pix[5]-pix[3]) +
                            abs(pix[0]-pix[8])+
                            abs(pix[2]-pix[6]));

                    return delta > 0;
                }

                void main()
                {
                    vec3 color = vec3(1.0, 1.0, 1.0);
                    float intensity = 0.5 + 0.5 * avg_intensity(texture2D(src, qt_TexCoord0));
                    color *= intensity;
                    vec4 colorAlpha = vec4(1.0, 1.0, 1.0, 1.0);
                    colorAlpha.rgb = color * (1.0 - IsEdge(qt_TexCoord0.xy));
                    gl_FragColor = colorAlpha;
                }
                "
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
        property point selectionStart
        property double prevX: 0
        property double prevY: 0
        propagateComposedEvents: true
        hoverEnabled: true
        anchors.fill: parent
//        drag.target: gameScene

        onPressed: {
            if(mouse.buttons & Qt.LeftButton && mouse.modifiers & Qt.ShiftModifier) {
                console.log("Started selection")
                selectionStart.x = mouse.x
                selectionStart.y = mouse.y
                isSelecting = true
            } else if(mouse.buttons & Qt.LeftButton) {
                isDragging = true
                prevX = mouse.x
                prevY = mouse.y
            }
        }

        onPositionChanged: {
            var relativeMouse = mapToItem(gameScene, mouse.x, mouse.y)

            // Selection
            if(isSelecting && mouse.buttons & Qt.LeftButton && mouse.modifiers & Qt.ShiftModifier) {
                if(mouse.x > selectionStart.x) {
                    selectionRectangle.x = selectionStart.x
                    selectionRectangle.width = mouse.x - selectionStart.x
                } else {
                    selectionRectangle.x = mouse.x
                    selectionRectangle.width = selectionStart.x - mouse.x
                }
                if(mouse.y > selectionStart.y) {
                    selectionRectangle.y = selectionStart.y
                    selectionRectangle.height = mouse.y - selectionStart.y
                } else {
                    selectionRectangle.y = mouse.y
                    selectionRectangle.height = selectionStart.y - mouse.y
                }
            }


            // Dragging
            if(isDragging && mouse.buttons & Qt.LeftButton) {
                gameScene.x += mouse.x - prevX
                gameScene.y += mouse.y - prevY
            }
            prevX = mouse.x
            prevY = mouse.y
        }

        onReleased: {
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

                selectedObjects = newSelection
                isSelecting = false
            }

            if(!isSelecting && !(mouse.modifiers & Qt.ShiftModifier)) {
                var deltaX = mouse.x - prevX
                var deltaY = mouse.y - prevY
                if(Math.sqrt(deltaX*deltaX + deltaY*deltaY) < 10) {
                    for(var i in selectedObjects) {
                        var entity = selectedObjects[i]
                        if(entity) {
                            entity.selected = false
                        }
                    }

                    selectedObjects = []
                }
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
                gameScene.targetScale *= 1.5
            } else if(wheel.angleDelta.y < 0) {
                gameScene.targetScale /= 1.5
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
