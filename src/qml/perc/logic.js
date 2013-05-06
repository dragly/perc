var sites;
var walkers = [];
var clusters = [];
var pressureSources = [];
var clusterComponent = Qt.createComponent("Cluster.qml")
var pressureSourceComponent = Qt.createComponent("sources/PressureSource.qml")

function createPressureSource() {
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
            var pressureSource = pressureSourceComponent.createObject(sceneRoot)
            if(pressureSource === null) {
                console.log("Could not create pressure source component.")
                console.log(pressureSourceComponent.errorString())
                return false
            }

            pressureSource.row = i
            pressureSource.col = j
            pressureSource.requestSelect.connect(sceneRoot.selectObject)
            found = true
            pressureSources.push(pressureSource)

        }

        nAttempts += 1
    }
}

function refreshPressures() {
    percolationSystem.clearPressureSources()
    for(var i in pressureSources) {
        var pressureSource = pressureSources[i]
        percolationSystem.addPressureSource(pressureSource)
    }
}

function createRandomWalker(type) {
//    console.log("Creating random walker")
    var component = Qt.createComponent("walkers/RandomWalker.qml")
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
            var walker = component.createObject(sceneRoot, {type: type});
            if(walker === null) {
                console.log("ERROR! Could note create RandomWalker!")
                return false;
            }
            walker.row = i
            walker.col = j
            found = true
            walkers.push(walker)
        }
        nAttempts += 1
    }
}

function createDirectionWalker(type) {
    if(type === undefined) {
        type = "left"
    }

//    console.log("Creating direction walker")
    var component = Qt.createComponent("walkers/DirectionWalker.qml")
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
                var walker = component.createObject(sceneRoot, {type: type});
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
