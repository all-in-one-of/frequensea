#ifndef NVR_H
#define NVR_H

#ifdef __APPLE__
    #define OVR_OS_MAC
#endif

extern "C" {
    #include "vec.h"
    #include "nwm.h"
    #include "ngl.h"
}

#include "OVR.h"
#include "OVR_CAPI_GL.h"

typedef struct {
    int index;
    ovrEyeType type;
    ovrEyeRenderDesc render_desc;
    int width;
    int height;
    mat4 projection;
    ovrPosef render_pose;
    vec3 view_adjust;
    GLuint fbo;
    ovrTexture texture;
    GLuint texture_id;
} nvr_eye;

typedef struct {
    ovrHmd hmd;
    nvr_eye left_eye;
    nvr_eye right_eye;
} nvr_device;

typedef void (*nvr_render_cb_fn)(nvr_device *device, nvr_eye *eye, void *);

nvr_device *nvr_device_init();
void nvr_device_destroy(nvr_device *device);
nwm_window *nvr_device_window_init(nvr_device *device);
void nvr_device_init_eyes(nvr_device *device);
void nvr_device_draw(nvr_device *device, nvr_render_cb_fn callback, void* ctx);
ngl_camera *nvr_device_eye_to_camera(nvr_device *device, nvr_eye *eye);

#endif // NVR_H
