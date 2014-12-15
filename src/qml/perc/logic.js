function randomSiteOnLargestCluster(percolationSystem) {
    var largestArea = percolationSystem.maxArea()
    var found = false
    var nAttempts = 0
    while(!found) {
        if(nAttempts > 10000) {
            console.log("Could not find random site!")
            return {row: 0, col: 0}
        }
        var i = parseInt(Math.random() * percolationSystem.nRows)
        var j = parseInt(Math.random() * percolationSystem.nCols)
        if(percolationSystem.area(i,j) === largestArea) {
            return { row: i, col: j }
        }
        nAttempts += 1
    }
}

function randomSite(percolationSystem) {
    var found = false;
    var nAttempts = 0;
    while(!found) {
        if(nAttempts > 10000) {
            console.log("Could not find random site!")
            return {row: 0, col: 0}
        }
        var i = parseInt(Math.random() * percolationSystem.nRows)
        var j = parseInt(Math.random() * percolationSystem.nCols)
        if(percolationSystem.movementCost(i,j) > 0) {
            return { row: i, col: j }
        }
        nAttempts += 1
    }
}

function createPressureSource(percolationSystem) {
    var found = false;
    var nAttempts = 0;
    var sourcesList = percolationSystem.pressureSources
    var site = randomSite(percolationSystem)
    var properties = {
        row: site.row,
        col: site.col,
        pressure: Math.random()
    }
    var pressureSource = entityManager.createEntityFromUrl("sources/PressureSource.qml", properties)
    sourcesList.push(pressureSource)
    percolationSystem.pressureSources = sourcesList
}

function refreshPressures(gameView, percolationSystem) {
    percolationSystem.clearPressureSources()
    for(var i in gameView.pressureSources) {
        var pressureSource = gameView.pressureSources[i]
        percolationSystem.addPressureSource(pressureSource)
    }
}

function createRandomWalker(type, team) {
    //    console.log("Creating random walker")
    var site = randomSite(percolationSystem)
    var properties = {
        type: type,
        team: team,
        row: site.row,
        col: site.col
    }
    var walker = entityManager.createEntityFromUrl("walkers/RandomWalker.qml", properties);
}

function createDirectionWalker(type, team) {
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
        if(percolationSystem.movementCost(i,j) > 0) {
            var occupiedNeighbors = 0;
            if(percolationSystem.movementCost(i + 1,j) > 0) {
                occupiedNeighbors += 1
            }
            if(percolationSystem.movementCost(i - 1,j) > 0) {
                occupiedNeighbors += 1
            }
            if(percolationSystem.movementCost(i,j + 1) > 0) {
                occupiedNeighbors += 1
            }
            if(percolationSystem.movementCost(i,j - 1) > 0) {
                occupiedNeighbors += 1
            }
            if(occupiedNeighbors < 2) { // only one way out - otherwise we might get stuck
                var properties = {
                    type: type,
                    team: team,
                    row: i,
                    col: j
                }
                var walker = entityManager.createEntityFromUrl("walkers/DirectionWalker.qml", properties);
                found = true
                //                walkers.push(walker)
            }
        }
        nAttempts += 1
    }
}

//function moveWalkers() {
//    for(var i in walkers) {
//        var walker = walkers[i]
//        walker.move();
//    }
//}
