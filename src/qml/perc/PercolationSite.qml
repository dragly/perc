import QtQuick 2.0

Rectangle {
    property bool occupied: false
    property int row: -1
    property int col: -1
    property double value: -1
    property int label: -1
    property int area: -1

    onColChanged: {
        x = col * 10
    }
    onRowChanged: {
        y = row * 10
    }

    width: 10
    height: 10
//    color: Qt.rgba(value, 0.5, 0.5, 1)
//    color: occupied ? "#E0F3DB" : "#43A2CA"
    color: Qt.rgba(0, (occupied ? 1 : 0.5), area / percolationSystem.maxArea(), 1)
}
