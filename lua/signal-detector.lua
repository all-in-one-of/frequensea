-- Detect signals on the ISM band (433 MHz) and show the "signature"

if NWM_OPENGL_TYPE == NWM_OPENGL then

    VERTEX_SHADER = [[
    #version 400
    layout (location = 0) in vec3 vp;
    layout (location = 1) in vec3 vn;
    layout (location = 2) in vec2 vt;
    out vec3 color;
    out vec2 texCoord;
    uniform mat4 uViewMatrix, uProjectionMatrix;
    uniform float uTime;
    void main() {
        color = vec3(1.0, 1.0, 1.0);
        texCoord = vt;
        gl_Position = vec4(vp.x*2, vp.z*2, 0, 1.0);
    }
    ]]

    FRAGMENT_SHADER = [[
    #version 400
    in vec3 color;
    in vec2 texCoord;
    uniform sampler2D uTexture;
    uniform float uAlpha;
    layout (location = 0) out vec4 fragColor;
    void main() {
        float r = texture(uTexture, texCoord).r * 80;
        fragColor = vec4(r, r, r, uAlpha);
    }
    ]]

else

    VERTEX_SHADER = [[
    attribute vec3 vp;
    attribute vec3 vn;
    attribute vec2 vt;
    varying vec3 color;
    varying vec2 texCoord;
    uniform mat4 uViewMatrix, uProjectionMatrix;
    uniform float uTime;
    void main() {
        color = vec3(1.0, 1.0, 1.0);
        texCoord = vt;
        gl_Position = vec4(vp.x*2, vp.z*2, 0, 1.0);
    }
    ]]

    FRAGMENT_SHADER = [[
    precision mediump float;
    varying vec3 color;
    varying vec2 texCoord;
    uniform sampler2D uTexture;
    uniform float uAlpha;
    void main() {
        float r = texture2D(uTexture, texCoord).a * 100;
        gl_FragColor = vec4(r, r, r, uAlpha);
    }
    ]]

end

STATE_DETECTING = 1
STATE_CAPTURING = 2
STATE_DRAWING = 3

function setup()
    freq = 433
    device = nrf_device_new(freq, "../rfdata/rf-200.500-big.raw")
    filter = nrf_iq_filter_new(device.sample_rate, 200e3, 97)

    detector = nrf_signal_detector_new()
    signal_threshold = 100
    state = STATE_DETECTING
    draw_buffer = nil
    have_signal = false
    buffer_index = 1
    alpha = 1

    camera = ngl_camera_new_look_at(0, 0, 0) -- Camera is unnecessary but ngl_draw_model requires it
    shader = ngl_shader_new(GL_TRIANGLES, VERTEX_SHADER, FRAGMENT_SHADER)
    texture = ngl_texture_new(shader, "uTexture")
    model = ngl_model_new_grid_triangles(2, 2, 1, 1)
    percentage_drawn = 0
end

function draw()
    ngl_clear(0.0, 0.0, 0.0, 1.0)

    if state == STATE_DETECTING then
        samples_buffer = nrf_device_get_samples_buffer(device)
        nrf_signal_detector_process(detector, samples_buffer)
        sd = nrf_signal_detector_get_standard_deviation(detector)
        if sd > signal_threshold then
            state = STATE_CAPTURING
            nrf_iq_filter_process(filter, samples_buffer)
            draw_buffer = nrf_iq_filter_get_buffer(filter)
        end
    elseif state == STATE_CAPTURING then
        samples_buffer = nrf_device_get_samples_buffer(device)
        nrf_signal_detector_process(detector, samples_buffer)
        sd = nrf_signal_detector_get_standard_deviation(detector)
        if sd > signal_threshold then
            nrf_iq_filter_process(filter, samples_buffer)
            filter_buffer = nrf_iq_filter_get_buffer(filter)
            nut_buffer_append(draw_buffer, filter_buffer)
        else
            state = STATE_DRAWING
            percentage_drawn = 0
            alpha = 1
        end
    elseif state == STATE_DRAWING then
        iq_buffer = nrf_buffer_to_iq_lines(draw_buffer, 4, percentage_drawn)

        ngl_texture_update(texture, iq_buffer, 1024, 1024)
        ngl_shader_uniform_set_float(shader, "uAlpha", alpha)
        ngl_draw_model(camera, model, shader)

        percentage_drawn = percentage_drawn + 0.005

        if percentage_drawn >= 0.9 then
            alpha = alpha - 0.01
        end

        if percentage_drawn >= 1 then
            state = STATE_DETECTING
            draw_buffer = nil
            percentage_drawn = 0
        end
    end
end
