// shader taken from: http://www.alcove-games.com/opengl-es-2-tutorials/lightmap-shader-fire-effect-glsl/

// from the default vertex shader
uniform sampler2D tex0;
varying vec2 tcoord;
varying vec4 color;

// must set in the program
uniform vec4 ambientColor;

void main() {
    vec4 texcolor = texture2D(tex0, tcoord);
    vec3 ambient = ambientColor.rgb * ambientColor.a;

    vec3 final = color.rgb * texcolor.rgb * ambient;
    gl_FragColor = vec4(final, texcolor.a);
}