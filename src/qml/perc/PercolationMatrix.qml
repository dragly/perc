import QtQuick 2.0

Rectangle {
    property int nRows: 0
    property int nCols: 0

    width: nRows * 10
    height: nCols * 10

    Canvas {
        anchors.fill: parent
        onPaint: {
            console.log("Painting matrix")
//            console.log("Paint requested!")
//            var ctx = getContext("2d");
//            var index = 0;
//            var maxArea = percolationSystem.maxArea();
//            for(var i = 0; i < percolationSystem.nRows; i++) {
//                for(var j = 0; j < percolationSystem.nCols; j++) {
//                    if(percolationSystem.isOccupied(i,j)) {
//                        var areaRatio = percolationSystem.area(i,j) / maxArea;
//                        ctx.fillStyle = Qt.rgba(0.1, areaRatio / 2 + 0.4, 0.9, 1);
//                    } else {
//                        ctx.fillStyle = "#084081";
//                    }
//                    ctx.fillRect(j*10,i*10,10,10);
//                    index += 1;
//                }
//            }
        }
    }
}
