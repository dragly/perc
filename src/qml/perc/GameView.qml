import QtQuick 2.0
import Qt.WebSockets 1.0

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
    property alias occupationTreshold: percolationSystem.occupationTreshold
    readonly property alias percolationSystem: percolationSystem
    readonly property alias entityManager: serverEntityManager

    property Team playerTeam: playerTeamInternal
    property int playerTeamId: 0

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
        resume()
    }

    onWidthChanged: {
        percolationSystemShader.updateSourceRect()
    }

    onHeightChanged: {
        percolationSystemShader.updateSourceRect()
    }

    Component.onCompleted: {}

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

    PercolationSystem {
        id: percolationSystem
        width: nCols
        height: nRows
        nRows: 10
        nCols: 10
        occupationTreshold: 0.55
        imageType: constructionMenu.imageType

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
        targetScale: 0.2
        percolationSystem: percolationSystem

        onCurrentScaleChanged: {
            percolationSystemShader.updateSourceRect()
        }

        onXChanged: {
            percolationSystemShader.updateSourceRect()
        }

        onYChanged: {
            percolationSystemShader.updateSourceRect()
        }

        smooth: true
    }

    EntityManager {
        id: entityManager
        gameScene: gameScene
        gameView: gameViewRoot
        percolationSystem: percolationSystem
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

        drag.target: gameScene

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

        onPositionChanged: {
            percolationSystemShader.lightPosX = mouse.x / (gameViewRoot.width)
            percolationSystemShader.lightPosY = mouse.y / (gameViewRoot.height)
            var relativeMouse = mapToItem(gameScene, mouse.x, mouse.y)
            gameScene.lightSource.setLightPos(relativeMouse.x, relativeMouse.y)
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
        selectedObjects: gameScene.selectedObjects
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

    WebSocketServer {
        id: server

        property var clients: []
        property int nextTeamId: 1

        host: "192.168.2.2"
        port: 44789
        accept: true
        listen: true

        function notifyClients() {
            var entities = [];
            for(var j in serverEntityManager.entities) {
                var entity = serverEntityManager.entities[j];
                entities.push(entity.properties);
            }
            var teams = [];
            for(var j in serverEntityManager.teams) {
                var team = serverEntityManager.teams[j];
                teams.push(team.properties);
            }

            var state = {
                type: "state",
                entities: entities,
                teams: teams
            };

            for(var i in clients) {
                var client = clients[i];
                client.webSocket.sendTextMessage(JSON.stringify(state));
            }
        }

        function spawnWalker(spawn, properties) {
            console.log("Spawn walker!");
            properties.row = spawn.row
            properties.col = spawn.col
            properties.team = spawn.team
            var walker = serverEntityManager.createEntityFromUrl("walkers/RandomWalker.qml", properties);
        }

        onClientConnected: {
            console.log("Client connected");

            var client = {webSocket: webSocket};
            clients.push(client);
            var teamComponent = Qt.createComponent("Team.qml");
            var team = teamComponent.createObject(server, {teamId: nextTeamId});
            serverEntityManager.teams.push(team);
            nextTeamId += 1;

            var playerSpawnSite = Logic.randomSiteOnLargestCluster(percolationSystem)
            var properties = {
                team: team,
                row: playerSpawnSite.row,
                col: playerSpawnSite.col,
                interval: 10000
            }
            var playerSpawn = serverEntityManager.createEntityFromUrl("spawns/Spawn.qml", properties)
            playerSpawn.spawnedWalker.connect(spawnWalker)

            webSocket.sendTextMessage(JSON.stringify({type: "welcome", team: team}));

            webSocket.onTextMessageReceived.connect(function(message) {
                var parsed = JSON.parse(message);
                for(var i in parsed.entities) {
                    var entityStrategy = parsed.entities[i];
                    for(var j in serverEntityManager.entities) {
                        var entity = serverEntityManager.entities[j];
                        if(entity.entityId === entityStrategy.entityId) {
                            if(entity.strategy !== undefined) {
                                entity.strategy = entityStrategy.strategy;
                            }
                        }
                    }
                }
            });
            webSocket.onStatusChanged.connect(function(status) {
                if(status === WebSocket.Closed) {
                    clients.splice(clients.indexOf(client), 1);
                }
            });
        }
        onErrorStringChanged: {
            console.log(qsTr("Server error: %1").arg(errorString));
        }
    }

    WebSocket {
        id: socket
        url: "ws://192.168.2.2:44789"
        active: true
        onTextMessageReceived: {
            var parsed = JSON.parse(message);
            console.log("Client received message", message);
            if(parsed.type === "welcome") {
                playerTeamId = parsed.team.teamId;
            }
            if(parsed.type === "state") {
                for(var i in entityManager.entities) {
                    var entity = entityManager.entities[i];
                    entity.toBeDeleted = true;
                }

                for(var i in parsed.entities) {
                    var parsedEntity = parsed.entities[i];
                    var entity;
                    var found = false;
                    for(var j in entityManager.entities) {
                        var existingEntity = entityManager.entities[j];
                        if(existingEntity.entityId === parsedEntity.entityId) {
                            entity = existingEntity;
                            found = true;
                        }
                    }
                    if(!found) {
                        entity = entityManager.createEntityFromUrl(parsedEntity.filename, {team: playerTeam});
                    }
                    for(var j in parsedEntity) {
                        entity.properties[j] = parsedEntity[j];
                    }
                    entity.toBeDeleted = false;
                }

                for(var i in entityManager.entities) {
                    var entity = entityManager.entities[i];
                    if(entity.toBeDeleted) {
                        entityManager.killLater(entity);
                    }
                }

                var strategyEntities = [];
                for(var i in entityManager.entities) {
                    var entity = entityManager.entities[i];
                    var entityStrategy = {
                        entityId: entity.entityId,
                        strategy: 1
                    }
                    strategyEntities.push(entityStrategy);
                }
                var strategy = {
                    entities: strategyEntities
                };
                socket.sendTextMessage(JSON.stringify(strategy));
            }
        }
        onStatusChanged: {
            if (socket.status == WebSocket.Error) {
                console.log(qsTr("Client error: %1").arg(socket.errorString));
            } else if (socket.status == WebSocket.Closed) {
                console.log(qsTr("Client socket closed."));
            }
        }
    }

    EntityManager {
        id: serverEntityManager
        gameScene: serverScene
        gameView: gameViewRoot
        percolationSystem: percolationSystem
    }

    Rectangle {

        anchors {
            left: parent.left
            top: parent.top
        }

        width: 300
        height: 300


        GameScene {
            id: serverScene
            anchors.fill: parent
            targetScale: 0.2
            scale: 0.2
            percolationSystem: percolationSystem
        }
    }

    Timer {
        id: advanceTimer
        property int triggers: 0
        running: (state === "running")
        interval: 1000 // hoping for 60 FPS
        repeat: true
        onTriggered: {
            var currentTime = Date.now()
            advance(currentTime)
            if(percolationSystem.tryLockUpdates()) {
                serverEntityManager.advance(currentTime)
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
                    winGame()
                } else if(fail) {
                    failGame()
                }

                percolationSystem.unlockUpdates()
            }

            server.notifyClients();
        }
    }
}
