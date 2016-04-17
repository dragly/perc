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
    property alias rowCount: percolationSystem.rowCount
    property alias columnCount: percolationSystem.columnCount
    property alias occupationTreshold: percolationSystem.occupationTreshold
    readonly property alias percolationSystem: percolationSystem
    readonly property alias entityManager: serverEntityManager

    property Team playerTeam: null

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
        serverPercolationSystem.pressureSources = []
        serverEntityManager.clear()
        serverPercolationSystem.initialize()
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

    Rectangle {
        id: backgroundRect
        color: "grey"
        anchors.fill: parent
    }

    PercolationSystem {
        id: percolationSystem
        objectName: "clientPercolationSystem"
        width: columnCount
        height: rowCount
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
        entityManager: entityManager

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
        energy: playerTeam ? playerTeam.energy : 0
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
                teams: teams,
                ticksSinceTurn: serverEntityManager.ticksSinceTurn,
                percolationSystem: {
                    rowCount: serverPercolationSystem.rowCount,
                    columnCount: serverPercolationSystem.columnCount,
                    valueMatrix: serverPercolationSystem.serialize(PercolationSystem.ValueImage),
                    teamMatrix: serverPercolationSystem.serialize(PercolationSystem.TeamImage),
                    occupationThreshold: serverPercolationSystem.occupationTreshold
                }
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
            var clientTeam = serverEntityManager.createTeam();
            nextTeamId += 1;

            var playerSpawnSite = Logic.randomSiteOnLargestCluster(serverPercolationSystem)
            var properties = {
                team: clientTeam,
                row: playerSpawnSite.row,
                col: playerSpawnSite.col,
                interval: 20000
            }
            var playerSpawn = serverEntityManager.createEntityFromUrl("spawns/Spawn.qml", properties)
            playerSpawn.spawnedWalker.connect(spawnWalker)

            for(var di = -1; di < 2; di++) {
                for(var dj = -1; dj < 2; dj++) {
                    var row = playerSpawn.row + di;
                    var column = playerSpawn.col + dj;
                    serverPercolationSystem.teamTag(playerSpawn.team.teamId, row, column);
                }
            }

            webSocket.sendTextMessage(JSON.stringify({type: "welcome", team: clientTeam.properties}));

            webSocket.onTextMessageReceived.connect(function(message) {
                console.log("Received message from", client.webSocket);
                var parsed = JSON.parse(message);
                for(var i in parsed.entities) {
                    var entityStrategy = parsed.entities[i];
                    for(var j in serverEntityManager.entities) {
                        var entity = serverEntityManager.entities[j];
                        if(entity.entityId === entityStrategy.entityId) {
                            if(entity.team !== clientTeam) {
                                console.warn("WARNING: Received command for entity from client with different team:")
                                console.log("Entity", entity.entityId, "on team", entity.team.teamId, "requested by team", clientTeam.teamId)
                                continue;
                            }

                            if(entity.strategy !== undefined) {
                                entity.strategy = entityStrategy.strategy;
                                entity.moveStrategy = entityStrategy.moveStrategy;
                            }
                        }
                    }
                }
            });
            webSocket.onStatusChanged.connect(function(status) {
                if(status === WebSocket.Closed) {
                    if(clients) {

                        clients.splice(clients.indexOf(client), 1);
                    }
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
            if(parsed.type === "welcome") {
                playerTeam = entityManager.createTeam({teamId: parsed.team.teamId});
                for(var j in parsedTeam) {
                    playerTeam.properties[j] = parsedTeam[j];
                }
            }
            if(parsed.type === "state") {
                percolationSystem.occupationTreshold = parsed.percolationSystem.occupationThreshold;
                percolationSystem.rowCount = parsed.percolationSystem.rowCount;
                percolationSystem.columnCount = parsed.percolationSystem.columnCount;
                percolationSystem.deserialize(PercolationSystem.ValueImage, parsed.percolationSystem.valueMatrix);
                percolationSystem.deserialize(PercolationSystem.TeamImage, parsed.percolationSystem.teamMatrix);

                entityManager.ticksSinceTurn = parsed.ticksSinceTurn;

                for(var i in entityManager.entities) {
                    var entity = entityManager.entities[i];
                    entity.toBeDeleted = true;
                }

                // TODO delete teams no longer found on server
                for(var i in parsed.teams) {
                    var parsedTeam = parsed.teams[i];
                    var foundTeam = false;
                    var team;
                    for(var j in entityManager.teams) {
                        var existingTeam = entityManager.teams[j];
                        if(parsedTeam.teamId === existingTeam.teamId) {
                            team = existingTeam;
                            foundTeam = true;
                        }
                    }
                    if(!foundTeam) {
                        team = entityManager.createTeam({teamId: parsedTeam.teamId});
                    }
                    for(var j in parsedTeam) {
                        team.properties[j] = parsedTeam[j];
                    }
                }

                for(var i in parsed.entities) {
                    var parsedEntity = parsed.entities[i];
                    var entity;
                    var parsedEntityTeam;

                    var foundTeam = false;
                    for(var k in entityManager.teams) {
                        var existingTeam = entityManager.teams[k];
                        if(existingTeam.teamId === parsedEntity.teamId) {
                            parsedEntityTeam = existingTeam;
                            foundTeam = true;
                        }
                    }

                    if(!foundTeam) {
                        console.log("WARNING: Got entity with unknown team!");
                    }

                    var foundEntity = false;
                    for(var j in entityManager.entities) {
                        var existingEntity = entityManager.entities[j];
                        if(existingEntity.entityId === parsedEntity.entityId) {
                            entity = existingEntity;
                            foundEntity = true;
                        }
                    }
                    if(!foundEntity) {
                        entity = entityManager.createEntityFromUrl(parsedEntity.filename, {entityId: parsedEntity.entityId, team: parsedEntityTeam});
                    }
                    for(var j in parsedEntity) {
                        entity.properties[j] = parsedEntity[j];
                    }
                    entity.team = parsedEntityTeam;
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
                    if(entity.team === playerTeam && entity.walker) {
                        entity.chooseStrategy();
                        var entityStrategy = {
                            entityId: entity.entityId,
                            strategy: entity.strategy,
                            moveStrategy: entity.moveStrategy
                        }
                        console.log("Sending strategy", entity.strategy, entity.moveStrategy)
                        strategyEntities.push(entityStrategy);
                    }
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
        percolationSystem: serverPercolationSystem
    }

    Rectangle {
        anchors {
            left: parent.left
            top: parent.top
        }
        height: entityManager.ticksSinceTurn / 10 * parent.height
        width: 20
        Behavior on height {
            NumberAnimation {
                duration: 400
                easing.type: Easing.InOutQuad
            }
        }
    }

    Rectangle {
        visible: false
        anchors {
            left: parent.left
            bottom: parent.bottom
        }

        width: 300
        height: 300

        PercolationSystem {
            id: serverPercolationSystem
            objectName: "serverPercolationSystem"
            width: columnCount
            height: rowCount
            rowCount: 64
            columnCount: 64

            occupationTreshold: 0.6
            imageType: constructionMenu.imageType
            smooth: false
        }

        ShaderEffectSource {
            id: effectSource
            sourceItem: serverPercolationSystem
            hideSource: true
            mipmap: false
            anchors.fill: parent
        }

        GameScene {
            id: serverScene

            property real scala: serverPercolationSystem.width / (serverPercolationSystem.rowCount * Defaults.GRID_SIZE)

            anchors.fill: parent

            entityManager: serverEntityManager
            scale: 0.2
            targetScale: 0.2
            onScalaChanged: console.log("scala", scala)
            percolationSystem: serverPercolationSystem

            smooth: false
        }
    }

    Timer {
        id: advanceTimer
        property int triggers: 0
        running: (state === "running")
        interval: 400
        repeat: true
        onTriggered: {
            var currentTime = Date.now()
            advance(currentTime)
            if(serverPercolationSystem.tryLockUpdates()) {
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

                serverPercolationSystem.requestRecalculation();

                serverPercolationSystem.unlockUpdates()
            }

            server.notifyClients();
        }
    }
}
