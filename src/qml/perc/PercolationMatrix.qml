import QtQuick 2.0

Rectangle {
    property int nRows: 0
    property int nCols: 0

    width: 100
    height: 100
    color: "pink"

//    Canvas {
//        anchors.fill: parent
//        onPaint: {
//            var ctx = getContext();
//            for(var i = 0; i < percolationSystem.nRows; i++) {
//                for(var j = 0; j < percolationSystem.nCols; j++) {
//                    var site = component.createObject(percolationMatrix);
//                    if(site === null) {
//                        console.log("ERROR! Could note create PercolationSite!")
//                        return false;
//                    }
//                    site.occupied = percolationSystem.isOccupied(i,j);
//                    site.row = i
//                    site.col = j
//                    site.value = percolationSystem.value(i,j)
//                    sites[i * nCols + j] = site;
//                    site.label = percolationSystem.label(i,j)
//                    site.area = percolationSystem.area(i,j)
//                }
//            }
//        }
//    }
}
