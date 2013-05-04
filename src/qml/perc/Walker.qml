import QtQuick 2.0

Rectangle {
    property int row: -1
    property int col: -1

    width: 10
    height: 10
    color: "#F03B20"

    onColChanged: {
        x = col * 10 + (10 - width) / 2
    }
    onRowChanged: {
        y = row * 10 + (10 - width) / 2
    }

    Behavior on x {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }

    Behavior on y {
        NumberAnimation {
            duration: 100
            easing.type: Easing.InOutQuad
        }
    }

    function move() {
        console.log("Move not implemented for walker...")
    }
}
