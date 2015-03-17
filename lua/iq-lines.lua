-- Visualize IQ data from the HackRF

VERTEX_SHADER = [[
#version 400
layout (location = 0) in vec3 vp;
layout (location = 1) in vec3 vn;
out vec3 color;
uniform mat4 uViewMatrix, uProjectionMatrix;
uniform float uTime;
void main() {
    color = vec3(1.0, 1.0, 1.0);
    vec2 pt = vec2((vp.x - 0.5) * 2, (vp.y - 0.5) * 2);
    gl_Position = vec4(pt.x, pt.y, 0.0, 1.0);
}
]]

FRAGMENT_SHADER = [[
#version 400
in vec3 color;
layout (location = 0) out vec4 fragColor;
void main() {
    fragColor = vec4(color, 0.95);
}
]]

function setup()
    freq = 143.2
    line_percentage = 0.04
    device = nrf_device_new(freq, "../rfdata/rf-200.500-big.raw")

    camera = ngl_camera_new_look_at(0, 0, 0) -- Shader ignores camera position, but camera object is required for ngl_draw_model
    shader = ngl_shader_new(GL_LINE_STRIP, VERTEX_SHADER, FRAGMENT_SHADER)
end

function draw()
    samples_buffer = nrf_device_get_samples_buffer(device)
    reduced_buffer = nut_buffer_reduce(samples_buffer, line_percentage)

    ngl_clear(0.2, 0.2, 0.2, 1.0)
    model = ngl_model_new_with_buffer(reduced_buffer)
    ngl_draw_model(camera, model, shader)
end

function clamp(v, min, max)
    if v < min then
        return min
    elseif v > max then
        return max
    else
        return v
    end
end

function on_key(key, mods)
    keys_frequency_handler(key, mods)
    if (mods == 4) then -- Alt key
        d = 0.001
    else
        d = 0.01
    end
    if key == KEY_COMMA then
        line_percentage = clamp(line_percentage - d, 0, 1)
        print("Line percentage: " .. line_percentage * 100 .. "%")
    elseif key == KEY_PERIOD then
        line_percentage = clamp(line_percentage + d, 0, 1)
        print("Line percentage: " .. line_percentage * 100 .. "%")
    end
end
