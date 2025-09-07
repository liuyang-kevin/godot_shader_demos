shader_type canvas_item;

uniform bool use_node_texture = true;

uniform int step_posterize : hint_range(0, 100, 1) = 20;
uniform int step_pixelated : hint_range(0, 1000, 1) = 720;

uniform vec3 color_A : source_color = vec3(0.5, 0.5, 0.0);
uniform vec3 color_B : source_color = vec3(0.1, 0.1, 0.1);

uniform bool dithering_bayer;
uniform bool animated_dithering;
uniform bool smooth_animate;

uniform float interval : hint_range(0.1, 5.0, 0.1) = 0.1;

//hint_screen_texture 提示会让这个 uniform 采样屏幕纹理（即后缓冲区的副本）
uniform sampler2D _screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

const mat4 THRESHOLD_MATRIX = mat4(
		vec4(1.0 / 17.0,  9.0 / 17.0,  3.0 / 17.0, 11.0 / 17.0),
		vec4(13.0 / 17.0,  5.0 / 17.0, 15.0 / 17.0,  7.0 / 17.0),
		vec4(4.0 / 17.0, 12.0 / 17.0,  2.0 / 17.0, 10.0 / 17.0),
		vec4(16.0 / 17.0,  8.0 / 17.0, 14.0 / 17.0,  6.0 / 17.0));
		
vec3 quntizarion_color(vec3 color){
	color = floor(color * vec3(float(step_posterize))) / vec3(float(step_posterize));
	return color;
}

vec2 pixelated(vec2 uv){
	uv = (vec2(ivec2(uv * float(step_pixelated))) + 0.5) / float(step_pixelated);
	return uv;
}

float rng_number(vec2 input){
	float rng;
	if (animated_dithering){
		if (smooth_animate){
			rng = fract(sin(dot(input, vec2(1242.1, 5514.12)) * 1.2911) * 155.12 * TIME);
		} else {
			rng = fract(sin(dot(input, vec2(1242.1, 5514.12)) * 1.2911) * 155.12 * floor(TIME / interval));
		}
	} else {
		rng = fract(sin(dot(input, vec2(1262.1, 5534.12)) * 2.4211) * 121355.1266);
	}

	return rng;
}

vec3 rng_dithering(vec3 color, vec2 uv){
	float randomness = color.r;
	if (randomness > rng_number(uv)){
		color = color_A;
	}else{
		color = color_B;
	}
	return color;
}

vec3 dithering(vec3 color, vec2 uv){
	vec2 reverse_uv = uv * vec2(float(step_pixelated));
	float bayer_index = THRESHOLD_MATRIX[int(reverse_uv.x) % 4][int(reverse_uv.y)% 4];
	if (bayer_index < color.r){
		color = vec3(color_A);
	} else{
		color = vec3(color_B);
	}
	return color;
}
void fragment() {
	vec2 aspect = vec2(1.0, SCREEN_PIXEL_SIZE.x / SCREEN_PIXEL_SIZE.y);
	vec3 color;
	if(use_node_texture){
		color = texture(TEXTURE, UV).rgb;
		color = texture(TEXTURE, pixelated(UV)).rgb;
	}else{
		color = texture(_screen_texture, UV).rgb;
		color = texture(_screen_texture, pixelated(UV)).rgb;
	}
	color = quntizarion_color(color);
	if (dithering_bayer){
		color = dithering(color, pixelated(UV * aspect));
	} else {
		color = rng_dithering(color, pixelated(UV * aspect));
	}
	//color = vec3(rng_number(UV));
	COLOR.rgb = color;

}