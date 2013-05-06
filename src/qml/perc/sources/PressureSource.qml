import QtQuick 2.0
import QtGraphicalEffects 1.0
import QtQuick.Particles 2.0

Rectangle {
    id: pressureSourceRoot

    property double pressure: 1
    property int row
    property int col

    //    radius: 10

    x: col * 10 + (10 - width) / 2
    y: row * 10 + (10 - height) / 2

    width: 7
    height: 7
    color: "blue"

    smooth: true

    //    SequentialAnimation {
    //        running: true
    //        loops: Animation.Infinite
    //        ParallelAnimation {
    //            NumberAnimation {
    //                target: pressureSourceRoot
    //                properties: "width,height"
    //                to: 8
    //                duration: 1000
    //                easing.type: Easing.InOutQuad
    //            }
    //            ColorAnimation {
    //                target: pressureSourceRoot
    //                properties: "color"
    //                to: "#FFFFA6"
    //                duration: 1000
    //                easing.type: Easing.InOutQuad
    //            }
    //        }
    //        ParallelAnimation {
    //            NumberAnimation {
    //                target: pressureSourceRoot
    //                properties: "width,height"
    //                to: 5
    //                duration: 1000
    //                easing.type: Easing.InOutQuad
    //            }
    //            ColorAnimation {
    //                target: pressureSourceRoot
    //                properties: "color"
    //                to: "#FFFFFF"
    //                duration: 1000
    //                easing.type: Easing.InOutQuad
    //            }
    //        }
    //    }

    Emitter {
        shape: EllipseShape{}
        system: particleSystem
        anchors.centerIn: parent
        height: 2
        width: 2
        group: "test"
        lifeSpan: 1000
        emitRate: 50
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

