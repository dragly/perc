import QtQuick 2.0

Rectangle {
    property int nRows: 0
    property int nCols: 0

    width: 100
    height: 100
    color: "pink"

    function initialize() {
        var component = Qt.createComponent("qml/perc/PercolationSite.qml")
        if(!component) {
            console.log("Error!")
        }
    }
}
