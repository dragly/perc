import QtQuick 2.0
import com.dragly.perc 1.0

Rectangle {
    width: 200
    height: 300
    color: "blue"
    Rectangle {
        x: 20
        y: 30
        color: "green"
        width: 100
        height: 100
    }

    PercolationMatrix {
        id: percolationMatrix

        function populate() {
            for(var i = 0; i < percolationSystem.nRows; i++) {
                for(var j = 0; j < percolationSystem.nCols; j++) {
                    console.log(percolationSystem.isOccupied(i,j));
                }
            }
        }
    }

    PercolationSystem {
        id: percolationSystem
    }

    Component.onCompleted: {
        percolationSystem.initialize(10,10,0.5)
        percolationMatrix.populate()
    }
}
