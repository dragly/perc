import QtQuick 2.0
import org.dragly.perc 1.0

import "logic.js" as Logic
import "defaults.js" as Defaults

Item {
    id: sceneRoot

    width: 100
    height: 62

//    property alias imageType: percolationSystem.imageType
    property PercolationSystem percolationSystem: null
    property real targetScale: 1.0
    property real currentScale: 1.0
    property alias scaleOriginX: scaleTransform.origin.x
    property alias scaleOriginY: scaleTransform.origin.y
//    property alias lightSource: lightSource
    property int scaleDuration: 200

    Component.onCompleted: {
        if(percolationSystem === null) {
            console.log("Error: PercolationSystem must be set in GameScene")
            Qt.quit()
            return
        }
    }

    onTargetScaleChanged: {
        targetScale = Math.max(0.1, Math.min(1.0, targetScale))

        scaleAnimation.from = currentScale
        scaleAnimation.to = targetScale
        scaleAnimation.restart()
    }

    PropertyAnimation {
        id: scaleAnimation
        target: sceneRoot
        properties: "currentScale"
        duration: scaleDuration
        easing.type: Easing.OutQuad
    }

    transform: [
        Scale {
            id: scaleTransform

            xScale: currentScale
            yScale: currentScale
        }
    ]

    ShaderEffectSource {
        id: shaderEffectSource
        sourceItem: percolationSystem
        hideSource: true
        width: nCols * Defaults.GRID_SIZE
        height: nRows * Defaults.GRID_SIZE
        mipmap: false
        smooth: false
    }

    ShaderEffect {
        width: nCols * Defaults.GRID_SIZE
        height: nRows * Defaults.GRID_SIZE
        property variant src: shaderEffectSource

        smooth: true
        fragmentShader: "
            varying highp vec2 qt_TexCoord0;
            uniform sampler2D src;
            float threshold(in float thr1, in float thr2 , in float val) {
                if (val < thr1) {return 0.0;}
                if (val > thr2) {return 1.0;}
                return val;
            }

            // averaged pixel intensity from 3 color channels
            float avg_intensity(in vec4 pix) {
                return (pix.r + pix.g + pix.b)/3.;
            }

            vec4 get_pixel(in vec2 coords, in float dx, in float dy) {
                return texture2D(src, coords + vec2(dx, dy));
            }

            // returns pixel color
            float IsEdge(in vec2 coords){
                float dxtex = 1.0 / 1024.0 /*image width*/;
                float dytex = 1.0 / 1024.0 /*image height*/;
                float pix[9];
                int k = -1;
                float delta;

                // read neighboring pixel intensities
                for (int i=-1; i<2; i++) {
                    for(int j=-1; j<2; j++) {
                        k++;
                        pix[k] = avg_intensity(get_pixel(coords,float(i)*dxtex, float(j)*dytex));
                    }
                }

                // average color differences around neighboring pixels
                delta = 0.25*(abs(pix[1]-pix[7])+
                        abs(pix[5]-pix[3]) +
                        abs(pix[0]-pix[8])+
                        abs(pix[2]-pix[6]));

                return delta > 0;
            }

            void main()
            {
                vec3 color = vec3(1.0, 1.0, 1.0);
                float intensity = 0.5 + 0.5 * avg_intensity(texture2D(src, qt_TexCoord0));
                color *= intensity;
                vec4 colorAlpha = vec4(1.0, 1.0, 1.0, 1.0);
                colorAlpha.rgb = color * (1.0 - IsEdge(qt_TexCoord0.xy));
                gl_FragColor = colorAlpha;
            }
            "
    }
}
