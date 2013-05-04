var sites;
var walkers = [];

function populate() {
//    var nRows = percolationSystem.nRows;
//    var nCols = percolationSystem.nCols;
//    sites = new Array(percolationSystem.nRows * percolationSystem.nCols)
//    var component = Qt.createComponent("PercolationSite.qml")
//    for(var i = 0; i < percolationSystem.nRows; i++) {
//        for(var j = 0; j < percolationSystem.nCols; j++) {
//            var site = component.createObject(percolationMatrix);
//            if(site === null) {
//                console.log("ERROR! Could note create PercolationSite!")
//                return false;
//            }
//            site.occupied = percolationSystem.isOccupied(i,j);
//            site.row = i
//            site.col = j
//            site.value = percolationSystem.value(i,j)
//            sites[i * nCols + j] = site;
//            site.label = percolationSystem.label(i,j)
//            site.area = percolationSystem.area(i,j)
//        }
//    }
}

function createRandomWalker() {
    var component = Qt.createComponent("RandomWalker.qml")
    var found = false;
    var nAttempts = 0;
    while(!found) {

        if(nAttempts > 100000) {
            console.log("Could not place walker!")
            break;
        }

        var i = parseInt(Math.random() * percolationSystem.nRows)
        var j = parseInt(Math.random() * percolationSystem.nCols)
        if(percolationSystem.isOccupied(i,j)) {
            var walker = component.createObject(percolationMatrix);
            if(walker === null) {
                console.log("ERROR! Could note create PercolationSite!")
                return false;
            }
            walker.row = i
            walker.col = j
            found = true
            walkers.push(walker)
        }
    }
}

function createDirectionWalker() {
    var component = Qt.createComponent("DirectionWalker.qml")
    var found = false;
    var nAttempts = 0;
    while(!found) {

        if(nAttempts > 100000) {
            console.log("Could not place walker!")
            break;
        }

        var i = parseInt(Math.random() * percolationSystem.nRows)
        var j = parseInt(Math.random() * percolationSystem.nCols)
        if(percolationSystem.isOccupied(i,j)) {
            var occupiedNeighbors = 0;
            if(percolationSystem.isOccupied(i + 1,j)) {
                occupiedNeighbors += 1
            }
            if(percolationSystem.isOccupied(i - 1,j)) {
                occupiedNeighbors += 1
            }
            if(percolationSystem.isOccupied(i,j + 1)) {
                occupiedNeighbors += 1
            }
            if(percolationSystem.isOccupied(i,j - 1)) {
                occupiedNeighbors += 1
            }
            if(occupiedNeighbors < 2) { // only one way out - otherwise we might get stuck
                var walker = component.createObject(percolationMatrix);
                if(walker === null) {
                    console.log("ERROR! Could not create PercolationSite!")
                    return false;
                }
                walker.row = i
                walker.col = j
                found = true
                walkers.push(walker)
            }
        }
        nAttempts += 1
    }
}

function moveWalkers() {
    for(var i in walkers) {
        var walker = walkers[i]
        walker.move();
    }
}
