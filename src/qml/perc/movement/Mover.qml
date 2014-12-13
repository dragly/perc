import QtQuick 2.0
import org.dragly.perc 1.0

import ".."

Item {
    signal move(var currentTime)
    property EntityBase owner: parent
    property var percolationSystem: parent.percolationSystem
    property var oldOwner: null

    onParentChanged: {
        parent.move.connect(move)
        if(oldOwner) {
            oldOwner.move.disconnect()
        }
        oldOwner = parent
    }
}
