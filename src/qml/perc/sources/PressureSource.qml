import QtQuick 2.0
import QtGraphicalEffects 1.0
import QtQuick.Particles 2.0

import ".."
import "../defaults.js" as Defaults

BaseEntity {
    id: pressureSourceRoot

//    signal requestSelect(var object)

    property double pressure: 1
    property double lastTime: Date.now()
    property double reductionPerSecond: 1e-6

    //    radius: Defaults.GRID_SIZE

    property string informationText: "Pressure source\nPressure: " + (Math.round(pressure * 100) / 100).toFixed(2)

    x: col * Defaults.GRID_SIZE + (Defaults.GRID_SIZE - width) / 2
    y: row * Defaults.GRID_SIZE + (Defaults.GRID_SIZE - height) / 2

    width: Defaults.GRID_SIZE * 0.6
    height: Defaults.GRID_SIZE * 0.6

    Component.onCompleted: {
        var sources = gameView.percolationSystem.pressureSources
        sources.push(pressureSourceRoot)
        gameView.percolationSystem.pressureSources = sources
    }

    Rectangle {
        id: rect
        anchors.fill: parent
        color: Qt.rgba(0.4, 0.4, 1 * pressureSourceRoot.pressure, 1)
        radius: Defaults.GRID_SIZE
    }

    smooth: true

    onPressureChanged: {
        if(pressure < 0) {
            pressure = 0
        }
    }

    onAdvance: {
        var interval = currentTime - lastTime
        pressure = pressure - reductionPerSecond * interval / 1000
    }

//    MouseArea {
//        anchors.fill: parent
//        onClicked: {
//            requestSelect(pressureSourceRoot)
//        }
//    }

    Emitter {
        shape: EllipseShape{}
//        system: particleSystem
        anchors.centerIn: parent
        height: Defaults.GRID_SIZE * 0.2
        width: Defaults.GRID_SIZE * 0.2
        group: "test"
        lifeSpan: 1000
        emitRate: (pressureSourceRoot.pressure > 0) ? 50 * pressureSourceRoot.pressure : 0
        size: Defaults.GRID_SIZE * 0.7
        endSize: Defaults.GRID_SIZE * 0.3
        acceleration: TargetDirection {
            //            angleVariation: 180
            targetX: Defaults.GRID_SIZE * 0.7
            targetY: Defaults.GRID_SIZE * 0.5
            magnitude: Defaults.GRID_SIZE
            magnitudeVariation: Defaults.GRID_SIZE
            targetVariation: Defaults.GRID_SIZE * 0.5
        }
    }

//    ParticleSystem {
//        id: particleSystem
//        ImageParticle {
//            groups: "test"
//            sprites: [
//                Sprite {
//                    name: "testsprite"
//                    source: "../particles/particle.png"
//                }
//            ]
//            //            entryEffect: ImageParticle.Scale
//        }
//    }
}

