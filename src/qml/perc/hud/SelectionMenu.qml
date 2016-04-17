import QtQuick 2.0

import ".."

Rectangle {
    id: selectionMenuRoot
    property Team playerTeam: null
    property list<BaseEntity> selectedObjects
    anchors.right: parent.right
    anchors.bottom: parent.bottom

    width: parent.width * 0.2
    height: parent.height * 0.2

    state: selectedObjects.length > 0 ? "active" : "hidden"

    Behavior on anchors.bottomMargin {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutQuad
        }
    }

    Item {
        anchors {
            fill: parent
            margins: 16
        }

        Text {
            id: gameObjectInfoText
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere

            text: {
                if(selectedObjects.length > 1) {
                    return selectedObjects.length + " items selected"
                } else if (selectedObjects.length === 1) {
                    return selectedObjects[0].team.name + "\n" +
                            "HP: " + selectedObjects[0].healthPoints + "\n" +
                            selectedObjects[0].informationText
                } else {
                    return "None selected"
                }
            }
        }
        Loader {
            anchors {
                top: gameObjectInfoText.bottom
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                topMargin: 16
            }
            sourceComponent: {
                if(selectedObjects.length < 1) {
                    return undefined;
                }
                var targetObject = selectedObjects[0];
                if(targetObject.controls && targetObject.team === playerTeam) {
                    return targetObject.controls;
                } else {
                    return undefined;
                }
            }
        }
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
