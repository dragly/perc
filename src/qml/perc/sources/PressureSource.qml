import QtQuick 2.0

Rectangle {
    property double pressure: 1
    property int row
    property int col

    radius: 10

    x: col * 10
    y: row * 10

    width: 10
    height: 10
    color: "white"
}
