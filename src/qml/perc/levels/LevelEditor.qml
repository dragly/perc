import QtQuick 2.0
import QtQuick.Controls 1.2
import Perc 1.0

import "../hud"
import ".."

import "../defaults.js" as Defaults
import "../logic.js" as Logic

Rectangle {
    id: levelEditorRoot
    signal resume
    signal restart
    signal pause
    signal exitToMainMenu

    width: 100
    height: 62

    onPause: {
        state = "paused"
    }

    onResume: {
        state = "running"
    }

    onRestart: {
        percolationSystem.pressureSources = []
        percolationSystem.initialize()
    }

    ConstructionMenu {
        id: constructionMenu
    }

    PercolationSystem {
        id: percolationSystem
        anchors.centerIn: parent
        width: columnCount
        height: rowCount
        scale: 1
        rowCount: 1000
        columnCount: 1000
        occupationTreshold: pSlider.value
        imageType: constructionMenu.imageType
        smooth: false
    }

    Row {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: parent.height * 0.05
        }
        Slider {
            id: pSlider
            width: levelEditorRoot.width * 0.2
            minimumValue: 0.0
            maximumValue: 1.0
        }
        Button {
            text: "Randomize"
            onClicked: {
                percolationSystem.randomizeMatrix()
            }
        }
    }
}
