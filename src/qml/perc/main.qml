import QtQuick 2.0

import "."
import "menus"

Rectangle {
    id: gameRoot

    width: 1280
    height: 720

    color: "grey"

    state: "main"

    function testMe() {
        console.log("Testme")
        state = "main"
    }

    Loader {
        id: levelLoader
        anchors.fill: parent
        opacity: 0
        enabled: false
        onLoaded: {
            item.exitToMainMenu.connect(gameRoot.testMe)
        }
    }

    MainMenu {
        id: mainMenu
        onSelectedLevel: {
            if(levelLoader.item !== null) {
                levelLoader.item.pause()
            }
            levelLoader.source = "levels/" + levelName
            gameRoot.state = "game"
            levelLoader.item.restart()
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
