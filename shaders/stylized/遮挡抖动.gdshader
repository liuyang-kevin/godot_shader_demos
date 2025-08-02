shader_type canvas_item;

uniform float dither_threshold : hint_range(0.0, 1.0);

float bayer2x2(vec2 pos) {
    int x = int(mod(pos.x, 2.0));
    int y = int(mod(pos.y, 2.0));
    int index = x + y * 2;
    float[4] matrix = float[](0.0, 0.5, 0.75, 0.25);
    return matrix[index];
}

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float d = bayer2x2(FRAGCOORD.xy);
    if (d > dither_threshold) {
        discard;
    }
    COLOR = tex;
}
