import QtQuick 2.0

Rectangle {
    id: gameObjectInfo
    property alias text: gameObjectInfoText.text
    anchors.right: parent.right
    anchors.bottom: parent.bottom

    width: parent.width * 0.2
    height: parent.height * 0.1

    state: "active"

    Behavior on anchors.bottomMargin {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutQuad
        }
    }
    Text {
        id: gameObjectInfoText
        anchors.centerIn: parent
        text: "Nothing selected"
        font.pixelSize: parent.height * 0.2
    }

    states: [
        State {
            name: "active"
            PropertyChanges {
                target: gameObjectInfo
                anchors.bottomMargin: 0
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: gameObjectInfo
                anchors.bottomMargin: -gameObjectInfo.height * 0.8
            }
        }
    ]
}
