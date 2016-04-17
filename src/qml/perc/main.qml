import QtQuick 2.0

import "."
import "menus"

Rectangle {
    id: gameRoot

    width: 1920
    height: 1080

    color: "grey"

    state: "main"

    function testMe() {
        console.log("Testme")
        state = "main"
    }

    Component.onCompleted: {
        levelLoader.source = "levels/test/TestLevel.qml"
    }

    Loader {
        id: levelLoader
        anchors.fill: parent
        opacity: 0
        enabled: false
        onLoaded: {
            gameRoot.state = "game"
            levelLoader.item.restart()
            levelLoader.item.resume()
            levelLoader.item.exitToMainMenu.connect(gameRoot.testMe)
        }
    }

    MainMenu {
        id: mainMenu
        opacity: 0
        enabled: false
        onSelectedLevel: {
            if(levelLoader.item !== null) {
                levelLoader.item.pause()
            }
            levelLoader.source = ""
            levelLoader.source = "levels/" + levelName
        }
    }

    states: [
        State {
            name: "main"
            PropertyChanges {
                target: mainMenu
                opacity: 1
                enabled: true
            }
        },
        State {
            name: "game"
            PropertyChanges {
                target: levelLoader
                opacity: 1
                enabled: true
            }
        }
    ]
}
