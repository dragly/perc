varying highp vec2 qt_TexCoord0;
uniform highp float qt_Opacity;
uniform sampler2D _source;
uniform sampler2D _source2;
uniform highp float _lightPosX;
uniform highp float _lightPosY;
uniform highp float diffuseBoost;
uniform highp float lightIntensity;
uniform highp float colorizeAmount;
uniform highp vec4 colorizeColor;
uniform bool switchX;
uniform bool switchY;

void main(void)
{
    highp vec2 pixPos = qt_TexCoord0;
    highp vec4 pix = texture2D(_source, pixPos.st);
//        highp vec4 pix2 = texture2D(_source2, pixPos.st);
    highp vec3 normal = vec3(1,0,0);  //normalize(pix2.rgb * 2.0 - 1.0);
    highp float xp = float(switchX) * (_lightPosX - pixPos.x) + float(!switchX) * (pixPos.x - _lightPosX);
    highp float yp = float(switchY) * (_lightPosY - pixPos.y) + float(!switchY) * (pixPos.y - _lightPosY);
    highp vec3 light_pos = normalize(vec3(xp, yp, lightIntensity));

    highp float diffuse = max(dot(normal, light_pos), 0.2);
    diffuse *= (1.0 + diffuseBoost);

    highp vec4 color = vec4(diffuse * pix.rgb, pix.a);
    color = mix(color, color.a * colorizeColor, colorizeAmount);

    gl_FragColor = color * qt_Opacity;
}
