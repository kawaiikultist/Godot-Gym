shader_type canvas_item;


uniform float pct : hint_range(0.0, 1.0, 0.01) = 0.0;
uniform float start : hint_range(0.0, 1.0, 0.01) = 0.45;
uniform float end : hint_range(0.0, 1.0, 0.01) = 0.9;
uniform float strength: hint_range(0.0, 1.0, 0.1) = 0.5;
uniform vec3 color : source_color = vec3(0.0, 0.0, 0.0);




void fragment() {
	float t = mix(end, start, pct);
	float s = mix(0.0, strength, pct);
	
	float dist = distance(vec2(0.5), UV);
	dist = smoothstep(t, end, dist);
	
	COLOR = vec4(color, dist * s);
}



