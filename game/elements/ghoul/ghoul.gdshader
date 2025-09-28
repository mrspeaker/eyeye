shader_type spatial;

uniform sampler2D sprite_texture : source_color, filter_nearest;
uniform float vignette_intensity = 0.4;
uniform float vignette_opacity : hint_range(0.0, 1.0) = 0.5;
uniform float scanlines_opacity : hint_range(0.0, 1.0) = 0.4;
uniform float scanlines_width : hint_range(0.0, 0.5) = 0.25;
uniform vec2 resolution = vec2(320.0, 240.0); // Set the number of rows and columns the texture will be divided in. Scanlines and grille will make a square based on these values

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0], INV_VIEW_MATRIX[1], INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
}

float vignette(vec2 uv){
    uv *= 1.0 - uv.xy;
    float vignette = uv.x * uv.y * 15.0;
    return pow(vignette, vignette_intensity * vignette_opacity * abs(sin(TIME*0.5)));
}

void fragment() {
	vec4 color = texture(sprite_texture, UV);
	vec4 ocolor = color;
	float scanlines = 0.5;
	float width = scanlines_width;
	width += abs(sin(TIME))+0.2;
	if (scanlines_opacity > 0.0) {
		float line = abs(sin(UV.y * (resolution.y * 3.14159265)));
		scanlines = smoothstep(width, width + 0.5, line);
		color.rgb = mix(color.rgb, color.rgb * vec3(scanlines), scanlines_opacity);
	}
	
	color.rgb *= vignette(UV);
	ALBEDO = color.rgb;
	ALPHA = color.a;
}