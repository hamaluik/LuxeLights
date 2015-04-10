// shader taken from: http://www.alcove-games.com/opengl-es-2-tutorials/lightmap-shader-fire-effect-glsl/

uniform sampler2D tex0;
uniform sampler2D lightMap;

varying vec2 tcoord;
varying vec4 color;
uniform vec4 ambientColor;
uniform vec2 resolution;

void main() {
	vec4 diffuseColour = texture2D(tex0, tcoord);
	vec2 lightCoord = (gl_FragCoord.xy / resolution.xy);
	vec4 light = texture2D(lightMap, lightCoord);

	vec3 ambient = ambientColor.rgb * ambientColor.a;
	vec3 intensity = ambient + light.rgb;
	vec3 finalColor = diffuseColour.rgb * intensity;

	gl_FragColor = color * vec4(finalColor, diffuseColour.a);
}
