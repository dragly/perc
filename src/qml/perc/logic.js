function createPressureSource() {
    var found = false;
    var nAttempts = 0;
    var sourcesList = gameViewRoot.pressureSources
    while(!found) {
        if(nAttempts > 100000) {
            console.log("Could not place walker!")
            break;
        }
        var i = parseInt(Math.random() * percolationSystem.nRows)
        var j = parseInt(Math.random() * percolationSystem.nCols)
        if(percolationSystem.isOccupied(i,j)) {
            var pressureSource = entityManager.createEntityFromUrl("sources/PressureSource.qml")
            pressureSource.row = i
            pressureSource.col = j
            pressureSource.pressure = Math.random()
//            pressureSource.requestSelect.connect(sceneRoot.selectObject)
            found = true
            sourcesList.push(pressureSource)
        }

        nAttempts += 1
    }
    gameViewRoot.pressureSources = sourcesList
}

function refreshPressures(timeDiff) {
    percolationSystem.clearPressureSources()
    for(var i in gameViewRoot.pressureSources) {
        var pressureSource = pressureSources[i]
        percolationSystem.addPressureSource(pressureSource)
    }
}

function createRandomWalker(type, team) {
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
            var properties = {
                type: type,
                team: team,
                row: i,
                col: j
            }
            var walker = entityManager.createEntityFromUrl("walkers/RandomWalker.qml", properties);
//            walker.lightSource = sceneRoot.lightSource
            found = true
//            walkers.push(walker)
        }
        nAttempts += 1
    }
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
