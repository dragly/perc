import QtQuick 2.0

import "defaults.js" as Defaults

Item {
    property int row: 0
    property int col: 0
    x: col * Defaults.GRID_SIZE
    y: row * Defaults.GRID_SIZE

    Behavior on x {
        NumberAnimation {
            duration: Defaults.TIME_STEP
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: Defaults.TIME_STEP * 1.1
        }
    }

    Behavior on rotation {
        NumberAnimation {
            duration: Defaults.TIME_STEP * 1.1
        }
    }
}
