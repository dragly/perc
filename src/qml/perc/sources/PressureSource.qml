import QtQuick 2.0
import QtGraphicalEffects 1.0
import QtQuick.Particles 2.0

Rectangle {
    id: pressureSourceRoot

    signal requestSelect(var object)

    property double pressure: 1
    property int row
    property int col

    //    radius: 10

    property string informationText: "Pressure source\nPressure: " + (Math.round(pressure * 100) / 100).toFixed(2)

    x: col * 10 + (10 - width) / 2
    y: row * 10 + (10 - height) / 2

    width: 6
    height: 6
    color: Qt.rgba(0.4, 0.4, 1 * pressure, 1)

    smooth: true

    onPressureChanged: {
        if(pressure < 0) {
            pressure = 0
        }
    }

    Timer {
        id: lowerValueTimer
        interval: 30 * 1000
        running: true
        repeat: true
        onTriggered: {
            pressure *= 0.9
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: {
            requestSelect(pressureSourceRoot)
        }
    }

    Emitter {
        shape: EllipseShape{}
        system: particleSystem
        anchors.centerIn: parent
        height: 2
        width: 2
        group: "test"
        lifeSpan: 1000
        emitRate: (pressureSourceRoot.pressure > 0) ? 50 * pressureSourceRoot.pressure : 0
        size: 7
        endSize: 3
        acceleration: TargetDirection {
            //            angleVariation: 180
            targetX: 7
            targetY: 5
            magnitude: 10
            magnitudeVariation: 10
            targetVariation: 5
        }
    }

    ParticleSystem {
        id: particleSystem
        ImageParticle {
            groups: "test"
            sprites: [
                Sprite {
                    name: "testsprite"
                    source: "../particles/particle.png"
                }
            ]
            //            entryEffect: ImageParticle.Scale
        }
    }
}

