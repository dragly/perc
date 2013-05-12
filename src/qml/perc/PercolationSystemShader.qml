import QtQuick 2.0
import com.dragly.perc 1.0
import "defaults.js" as Defaults

/* Simple normal mapping shader */

ShaderEffect {
    id: root

    property variant source

    // Lightsource which defines the position of light
    property NMapLightSource lightSource
    // Boost diffuse effect of this item
    property real diffuseBoost: 0.0
    // Light intensity from source or alternatively custom intensity for this item
    property real lightIntensity: lightSource.lightIntensity
    // Optional 'colorize' effect to apply for the item, can be used for fog effect
    property color colorizeColor: "#404040"
    property real colorizeAmount: 0.0

    /* Private */
    property real _lightPosX: lightSource.lightPosX / (gameScene.width)
    property real _lightPosY: lightSource.lightPosY / (gameScene.height)

    property variant _source: ShaderEffectSource { sourceItem: source; hideSource: true; mipmap: false }
//    property variant _source2: ShaderEffectSource { sourceItem: percoItem; hideSource: true; mipmap: false }

    fragmentShader: "
varying highp vec2 qt_TexCoord0;
uniform highp float qt_Opacity;
uniform sampler2D _source;
//uniform sampler2D _source2;
uniform highp float _lightPosX;
uniform highp float _lightPosY;
uniform highp float diffuseBoost;
uniform highp float lightIntensity;
uniform highp float colorizeAmount;
uniform highp vec4 colorizeColor;

void main(void)
{
    highp vec2 pixPos = qt_TexCoord0;
    highp vec4 pix = texture2D(_source, pixPos.st);
//    highp vec4 pix2 = texture2D(_source, pixPos.st);
//    highp float lightness = sqrt(dot(pix2,pix2));
//    highp vec3 normal = normalize(vec3(0,0,1) + pix2.rgb * 2.0 - 1.0);
    highp vec3 normal = normalize(vec3(0.0,0.0,1));
    highp float xp = (_lightPosX - pixPos.x);
    highp float yp = (_lightPosY - pixPos.y);
    highp vec3 light_pos = normalize(vec3(xp, yp, lightIntensity));

    highp float diffuse = max(dot(normal, light_pos), 0.2);
    diffuse *= (1.0 + diffuseBoost);

    highp vec4 color = vec4(diffuse * pix.rgb, pix.a);
    color = mix(color, color.a * colorizeColor, colorizeAmount);

    gl_FragColor = color * qt_Opacity;
}

    "
}
