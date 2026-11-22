/* Minimal EGL/GLES2 RGB565 probe for Lima (issue #5).
 * Builds in an ARMv7 Debian container with libgbm/libegl/libgles dev packages.
 * Run on the box as a user in the video group; no DRM master required.
 */
#include <EGL/egl.h>
#include <EGL/eglext.h>
#include <GLES2/gl2.h>
#include <gbm.h>
#include <drm_fourcc.h>
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef EGL_LINUX_DMA_BUF_EXT
#define EGL_LINUX_DMA_BUF_EXT 0x3270
#endif
#ifndef EGL_LINUX_DRM_FOURCC_EXT
#define EGL_LINUX_DRM_FOURCC_EXT 0x3271
#endif
#ifndef EGL_DMA_BUF_PLANE0_FD_EXT
#define EGL_DMA_BUF_PLANE0_FD_EXT 0x3272
#endif
#ifndef EGL_DMA_BUF_PLANE0_OFFSET_EXT
#define EGL_DMA_BUF_PLANE0_OFFSET_EXT 0x3273
#endif
#ifndef EGL_DMA_BUF_PLANE0_PITCH_EXT
#define EGL_DMA_BUF_PLANE0_PITCH_EXT 0x3274
#endif
#ifndef EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT
#define EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT 0x3275
#endif
#ifndef EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT
#define EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT 0x3276
#endif

typedef void (*image_target_texture_fn)(GLenum, void *);

static PFNEGLGETPLATFORMDISPLAYEXTPROC get_platform_display;
static PFNEGLCREATEIMAGEKHRPROC create_image;
static PFNEGLDESTROYIMAGEKHRPROC destroy_image;
static image_target_texture_fn image_target_texture;

static void report_gl(const char *what)
{
   GLenum e = glGetError();
   printf("%-34s glGetError=0x%04x (%s)\n", what, e,
          e == GL_NO_ERROR ? "OK" : "ERROR");
}

int main(void)
{
   const int w = 64, h = 64;
   int fd = open("/dev/dri/card0", O_RDWR);
   if (fd < 0) { perror("open card0"); return 1; }

   struct gbm_device *gbm = gbm_create_device(fd);
   if (!gbm) { fprintf(stderr, "gbm_create_device failed\n"); return 1; }

   get_platform_display = (PFNEGLGETPLATFORMDISPLAYEXTPROC)
      eglGetProcAddress("eglGetPlatformDisplayEXT");
   create_image = (PFNEGLCREATEIMAGEKHRPROC)eglGetProcAddress("eglCreateImageKHR");
   destroy_image = (PFNEGLDESTROYIMAGEKHRPROC)eglGetProcAddress("eglDestroyImageKHR");
   image_target_texture = (image_target_texture_fn)
      eglGetProcAddress("glEGLImageTargetTexture2DOES");
   if (!get_platform_display || !create_image || !image_target_texture) {
      fprintf(stderr, "missing EGL_KHR_platform_gbm or EGL_KHR_image_base\n");
      return 1;
   }

   EGLDisplay dpy = get_platform_display(EGL_PLATFORM_GBM_KHR, gbm, NULL);
   EGLint major, minor;
   if (!dpy || !eglInitialize(dpy, &major, &minor)) {
      fprintf(stderr, "eglInitialize failed\n"); return 1;
   }
   printf("EGL %d.%d vendor=%s\n", major, minor,
          eglQueryString(dpy, EGL_VENDOR));

   const EGLint cfg_attribs[] = {
      EGL_RENDERABLE_TYPE, EGL_OPENGL_ES2_BIT,
      EGL_NONE
   };
   EGLConfig cfg; EGLint n;
   if (!eglChooseConfig(dpy, cfg_attribs, &cfg, 1, &n) || n < 1) {
      fprintf(stderr, "eglChooseConfig failed\n"); return 1;
   }
   const EGLint ctx_attribs[] = { EGL_CONTEXT_CLIENT_VERSION, 2, EGL_NONE };
   EGLContext ctx = eglCreateContext(dpy, cfg, EGL_NO_CONTEXT, ctx_attribs);
   if (ctx == EGL_NO_CONTEXT) { fprintf(stderr, "eglCreateContext failed\n"); return 1; }
   eglMakeCurrent(dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, ctx);
   printf("GL_RENDERER=%s\nGL_VERSION=%s\n",
          glGetString(GL_RENDERER), glGetString(GL_VERSION));

   /* Control: ordinary sized 16-bit texture upload. */
   GLuint tex; glGenTextures(1, &tex); glBindTexture(GL_TEXTURE_2D, tex);
   unsigned short pixels[64 * 64];
   memset(pixels, 0xf8, sizeof(pixels));
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB565, w, h, 0,
                GL_RGB, GL_UNSIGNED_SHORT_5_6_5, pixels);
   report_gl("GL_RGB565 / UNSIGNED_SHORT_5_6_5");

   /* Unsized variant used by some drivers. */
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, w, h, 0,
                GL_RGB, GL_UNSIGNED_SHORT_5_6_5, pixels);
   report_gl("GL_RGB / UNSIGNED_SHORT_5_6_5");

   /* 32-bit control texture. */
   unsigned int rgba[64 * 64];
   memset(rgba, 0xff, sizeof(rgba));
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0,
                GL_RGBA, GL_UNSIGNED_BYTE, rgba);
   report_gl("GL_RGBA / UNSIGNED_BYTE (control)");

   /* GBM BO + dmabuf EGLImage with RGB565. */
   struct gbm_bo *bo = gbm_bo_create(gbm, w, h, GBM_FORMAT_RGB565,
                                     GBM_BO_USE_RENDERING | GBM_BO_USE_LINEAR);
   if (!bo) { fprintf(stderr, "gbm_bo_create RGB565 failed\n"); return 1; }
   int dmabuf = gbm_bo_get_fd(bo);
   printf("gbm bo RGB565 fd=%d stride=%u\n", dmabuf, gbm_bo_get_stride(bo));
   if (dmabuf >= 0) {
      const EGLint img_attribs[] = {
         EGL_LINUX_DRM_FOURCC_EXT, DRM_FORMAT_RGB565,
         EGL_WIDTH, w, EGL_HEIGHT, h,
         EGL_DMA_BUF_PLANE0_FD_EXT, dmabuf,
         EGL_DMA_BUF_PLANE0_OFFSET_EXT, 0,
         EGL_DMA_BUF_PLANE0_PITCH_EXT, (EGLint)gbm_bo_get_stride(bo),
         EGL_DMA_BUF_PLANE0_MODIFIER_LO_EXT, 0,
         EGL_DMA_BUF_PLANE0_MODIFIER_HI_EXT, 0,
         EGL_NONE
      };
      EGLImageKHR img = create_image(dpy, EGL_NO_CONTEXT,
                                     EGL_LINUX_DMA_BUF_EXT, NULL, img_attribs);
      printf("eglCreateImageKHR RGB565 dmabuf: %s\n",
             img != EGL_NO_IMAGE_KHR ? "OK" : "FAILED");
      if (img != EGL_NO_IMAGE_KHR) {
         glBindTexture(GL_TEXTURE_2D, tex);
         image_target_texture(GL_TEXTURE_2D, img);
         report_gl("glEGLImageTargetTexture2DOES RGB565");
         destroy_image(dpy, img);
      }
      close(dmabuf);
   }
   gbm_bo_destroy(bo);

   eglMakeCurrent(dpy, EGL_NO_SURFACE, EGL_NO_SURFACE, EGL_NO_CONTEXT);
   eglDestroyContext(dpy, ctx);
   eglTerminate(dpy);
   gbm_device_destroy(gbm);
   close(fd);
   return 0;
}
