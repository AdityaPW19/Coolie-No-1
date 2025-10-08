shader_type canvas_item;

uniform float blur_amount : hint_range(0.0, 10.0) = 0.0;

void fragment() {
    vec2 tex_offset = vec2(blur_amount * 0.001);

    vec4 color = vec4(0.0);

    // Sample in a 5x5 grid around the current pixel
    for (int x = -2; x <= 2; x++) {
        for (int y = -2; y <= 2; y++) {
            vec2 offset = vec2(float(x), float(y)) * tex_offset;
            color += texture(TEXTURE, UV + offset);
        }
    }

    color /= 25.0; // total number of samples
    COLOR = color;
}
