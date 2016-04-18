import QtQuick 2.0
import QtQuick.Controls 1.4
import Qt.WebSockets 1.0
import Qt.labs.settings 1.0

import Perc 1.0

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

    function applyProperties(object, properties) {
        if(!object){
            console.warn("WARNING: apply properties got missing object: " + object);
            return;
        }

        for(var i in properties) {
            var prop = properties[i];
            if(!object.hasOwnProperty("persistentProperties")) {
                console.warn("WARNING: Object " + object + " is missing persistentProperties property.");
                continue;
            }
            var found = false;
            for(var j in object.persistentProperties) {
                var propertyGroup = object.persistentProperties[j];
                if(!propertyGroup.hasOwnProperty(i)) {
                    continue;
                }
                found = true;
                if(typeof(prop) === "object" && typeof(propertyGroup[i]) == "object") {
                    applyProperties(propertyGroup[i], prop);
                } else {
                    propertyGroup[i] = prop;
                }
            }
            if(!found) {
                console.warn("WARNING: Cannot assign to " + i + " on savedProperties of " + object);
            }
        }
    }

    function generateProperties(entity) {
        if(!entity) {
            return undefined;
        }
        var result = {};
        for(var i in entity.persistentProperties) {
            var properties = entity.persistentProperties[i];
            for(var name in properties) {
                var prop = properties[name];
                if(typeof(prop) === "object") {
                    result[name] = generateProperties(prop);
                } else {
                    result[name] = prop;
                }
            }
        }
        return result;
    }

    onPause: {
        state = "paused"
    }

    onResume: {
        state = "running"
    }

    onRestart: {
        console.log("Restart!");
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
        objectName: "clientEntityManager"
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
        playerTeamName: playerTeam ? playerTeam.name : "Unknown team"
        playerTeamColor: playerTeam ? playerTeam.color : "purple"
        teamAreas: percolationSystem.teamAreas
        onPauseClicked: {
            pause()
        }
    }

    SelectionMenu {
        id: gameObjectInfo
        selectedObjects: gameScene.selectedObjects
        playerTeam: gameViewRoot.playerTeam
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

        host: "127.0.0.1"
        port: 44789
        accept: true
        listen: false

        function notifyClients() {
            var entities = [];
            for(var j in serverEntityManager.entities) {
                var entity = serverEntityManager.entities[j];
                entities.push(generateProperties(entity));
            }
            var teams = [];
            for(var j in serverEntityManager.teams) {
                var team = serverEntityManager.teams[j];
                teams.push(generateProperties(team));
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
                col: playerSpawnSite.col
            }
            var playerSpawn = serverEntityManager.createEntityFromUrl("spawns/Spawn.qml", properties);

            for(var di = -1; di < 2; di++) {
                for(var dj = -1; dj < 2; dj++) {
                    var row = playerSpawn.row + di;
                    var column = playerSpawn.col + dj;
                    serverPercolationSystem.teamTag(playerSpawn.team.teamId, row, column);
                }
            }

            webSocket.sendTextMessage(JSON.stringify({type: "welcome", team: generateProperties(clientTeam)}));

            webSocket.onTextMessageReceived.connect(function(message) {
                var parsed = JSON.parse(message);
                for(var i in parsed.entities) {
                    var parsedEntity = parsed.entities[i];
                    for(var j in serverEntityManager.entities) {
                        var entity = serverEntityManager.entities[j];
                        if(entity.entityId === parsedEntity.entityId) {
                            if(entity.team !== clientTeam) {
                                console.warn("WARNING: Received command for entity from client with different team:")
                                console.log("Entity", entity.entityId, "on team", entity.team.teamId, "requested by team", clientTeam.teamId)
                                continue;
                            }
                            if(entity.walker) {
                                entity.strategy = parsedEntity.strategy;
                                entity.moveStrategy = parsedEntity.moveStrategy;
                            }
                        }
                    }
                }
            });
            webSocket.onStatusChanged.connect(function(status) {
                if(status === WebSocket.Closed) {
                    serverEntityManager.removeTeamsEntities(clientTeam);
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
        active: false
        onTextMessageReceived: {
            var parsed = JSON.parse(message);
            if(parsed.type === "welcome") {
                console.log("Got welcome message from server!");
                console.log(message);
                playerTeam = entityManager.createTeam({teamId: parsed.team.teamId});
                applyProperties(playerTeam, parsed.team);
                console.log("We are team", playerTeam.teamId);
            }
            if(parsed.type === "state") {
                percolationSystem.occupationTreshold = parsed.percolationSystem.occupationThreshold;
                percolationSystem.rowCount = parsed.percolationSystem.rowCount;
                percolationSystem.columnCount = parsed.percolationSystem.columnCount;
                percolationSystem.deserialize(PercolationSystem.ValueImage, parsed.percolationSystem.valueMatrix);
                percolationSystem.deserialize(PercolationSystem.TeamImage, parsed.percolationSystem.teamMatrix);

                for(var i in entityManager.entities) {
                    var entity = entityManager.entities[i];
                    entity.toBeDeleted = true;
                }

                for(var i in entityManager.teams) {
                    var team = entityManager.teams;
                    team.toBeDeleted = true;
                }

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
                    team.toBeDeleted = false;
                    applyProperties(team, parsedTeam);
                }

                // inform percolationSystem about teams
                var teamColors = {};
                for(var i in entityManager.teams) {
                    var team = entityManager.teams[i];
                    teamColors[team.teamId] = team.color;
                }
                percolationSystem.teamColors = teamColors;

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
                    applyProperties(entity, parsedEntity);
                    entity.team = parsedEntityTeam;
                    entity.toBeDeleted = false;
                }

                for(var i in entityManager.entities) {
                    var entity = entityManager.entities[i];
                    if(entity.toBeDeleted) {
                        entityManager.killLater(entity);
                    }
                }

                for(var i in entityManager.teams) {
                    var team = entityManager.teams[i];
                    if(team.toBeDeleted) {
                        console.log("Removing team", team);
                        entityManager.removeTeamsEntities(team);
                    }
                }

                var strategyEntities = [];
                for(var i in entityManager.entities) {
                    var entity = entityManager.entities[i];
                    if(entity.team === playerTeam && entity.walker) {
                        entity.chooseStrategy();
                        var walkerStrategy = {
                            entityId: entity.entityId,
                            strategy: entity.strategy,
                            moveStrategy: entity.moveStrategy
                        }
                        strategyEntities.push(walkerStrategy);
                    }
                }

                var strategy = {
                    entities: strategyEntities
                };
                socket.sendTextMessage(JSON.stringify(strategy));

                entityManager.clearDeadItems();
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
        objectName: "serverEntityManager"
        gameScene: serverScene
        gameView: gameViewRoot
        percolationSystem: serverPercolationSystem
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
            rowCount: 48
            columnCount: 48

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
    Row {
        anchors {
            bottom: parent.bottom
        }

        TextField {
            id: serverTextField
            text: "127.0.0.1"
        }

        TextField {
            id: serverPortTextField
            text: "44790"
        }

        Button {
            text: "Serve"
            onClicked: {
                server.host = serverTextField.text;
                server.port = parseInt(serverPortTextField.text);
                server.listen = !server.listen;
            }
        }

        TextField {
            id: clientTextField
            text: "ws://127.0.0.1:44790"
        }

        Button {
            text: "Connect"
            onClicked: {
                socket.url = clientTextField.text;
//                socket.active = !socket.active;
            }
        }
    }

    Settings {
        property alias serverHost: serverTextField.text
        property alias serverPort: serverPortTextField.text
        property alias socketUrl: clientTextField.text
    }
}
