import QtQuick 2.0

import ".."

Rectangle {
    id: selectionMenuRoot
    property list<EntityBase> selectedObjects
    anchors.right: parent.right
    anchors.bottom: parent.bottom

    width: parent.width * 0.2
    height: parent.height * 0.1

    state: selectedObjects.length > 0 ? "active" : "hidden"

    Behavior on anchors.bottomMargin {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutQuad
        }
    }

    Text {
        id: gameObjectInfoText
        anchors.centerIn: parent

        text: {
            if(selectedObjects.length > 1) {
                return selectedObjects.length + " items selected"
            } else if (selectedObjects.length === 1) {
                return selectedObjects[0].informationText
            } else {
                return "None selected"
            }
        }

        font.pixelSize: parent.height * 0.2
    }

    states: [
        State {
            name: "active"
            PropertyChanges {
                target: selectionMenuRoot
                anchors.bottomMargin: 0
            }
        },
        State {
            name: "hidden"
            PropertyChanges {
                target: selectionMenuRoot
                anchors.bottomMargin: -selectionMenuRoot.height * 0.8
            }
        }
    ]
}
