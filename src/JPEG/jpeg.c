#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <jpeglib.h>
#include <setjmp.h>

#include "sac.h"

/*
 * Directly copied from the libjpeg examples.
 * TODO: cleanup!
 */
struct my_error_mgr {
    struct jpeg_error_mgr pub;  /* "public" fields */
      jmp_buf setjmp_buffer;  /* for return to caller */
};

typedef struct my_error_mgr * my_error_ptr;

METHODDEF(void)
my_error_exit (j_common_ptr cinfo)
{
    my_error_ptr myerr = (my_error_ptr) cinfo->err;
      (*cinfo->err->output_message) (cinfo);

        longjmp(myerr->setjmp_buffer, 1); 
}


#define array_nt  (array, T_OLD((AKD, (NHD, (NUQ, )))))
#define ret_nt    (ret,   T_OLD((AKD, (NHD, (NUQ, )))))

/*
 * Read a JPEG file from disk
 */
void SAC_JPEG_jpeg2array( SAC_ND_PARAM_out( array_nt, int),
                          FILE *fp)
{
  int *data;

  struct jpeg_decompress_struct cinfo;
  struct my_error_mgr jerr;

  JSAMPARRAY buffer;

  int w;
  int h;

  cinfo.err = jpeg_std_error(&jerr.pub);
  jerr.pub.error_exit = my_error_exit;

  /*
   * Check for errors
   */
  if (setjmp(jerr.setjmp_buffer)) {
    jpeg_destroy_decompress(&cinfo);
    SAC_RuntimeError( "Error when reading JPEG file!");
    return;
  }

  /*
   * Check for the number of colors
   */
  if (cinfo.output_components != 3) {
    SAC_RuntimeError( "Invalid number of colors!\n");
  }


  jpeg_create_decompress(&cinfo);
  jpeg_stdio_src(&cinfo, fp);
  (void) jpeg_read_header(&cinfo, TRUE);
  (void) jpeg_start_decompress(&cinfo);

  w = cinfo.output_width;
  h = cinfo.output_height;

  buffer = (*cinfo.mem->alloc_sarray) ((j_common_ptr) &cinfo, JPOOL_IMAGE, w*3, 1);
  data = malloc(sizeof(int) * w * h * 3);

  /*
   * Read in the entire JPEG image
   */
  for(int i = 0; i < h; i++) {
    (void) jpeg_read_scanlines(&cinfo, buffer, 1);
    for(int j = 0; j < w; j++) {
      for(int k = 0; k < 3; k++) {
        data[i*(w*3)+j*3+k] = GETJSAMPLE(buffer[0][j*3+k]);
      }
    }
  }

  (void) jpeg_finish_decompress(&cinfo);

  jpeg_destroy_decompress(&cinfo);

  SAC_ND_DECL__DATA( ret_nt, int, )
  SAC_ND_DECL__DESC( ret_nt, )
  int SAC_ND_A_MIRROR_DIM( ret_nt) = 3;
  SAC_ND_ALLOC__DESC( ret_nt, dims)
  SAC_ND_SET__RC( ret_nt, 1)
  SAC_ND_A_DESC_SHAPE( ret_nt, 0) = h;
  SAC_ND_A_DESC_SHAPE( ret_nt, 1) = w;
  SAC_ND_A_DESC_SHAPE( ret_nt, 2) = 3;
  SAC_ND_A_FIELD( ret_nt) = data;
  SAC_ND_RET_out( array_nt, ret_nt)
}

/*
 * Write an image in JPEG format to disk
 */
void SAC_JPEG_array2jpeg( FILE *fp,
                          SAC_ND_PARAM_in_nodesc( array_nt, int),
                          int shape[2],
                          int quality)
{
  const int w = shape[1];
  const int h = shape[0];

  struct jpeg_compress_struct cinfo;
  struct jpeg_error_mgr jerr;

  JSAMPARRAY buffer;

  cinfo.err = jpeg_std_error(&jerr);
  jpeg_create_compress(&cinfo);

  jpeg_stdio_dest(&cinfo, fp);

  cinfo.image_width = w;
  cinfo.image_height = h;
  cinfo.input_components = 3;
  cinfo.in_color_space = JCS_RGB;

  jpeg_set_defaults(&cinfo);
  jpeg_set_quality(&cinfo, quality, TRUE);

  jpeg_start_compress(&cinfo, TRUE);

  buffer = (*cinfo.mem->alloc_sarray)((j_common_ptr) &cinfo, JPOOL_IMAGE, w*3, 1);

  /*
   * For each row we copy it first to a buffer that can be handled by the jpeg
   * library, after that it is copied to the jpeg file
   */
  for(int i = 0; i < h; i++) {
    for (int j = 0; j < w*3; j++) {
      buffer[0][j] = (JSAMPLE)SAC_ND_A_FIELD(array_nt)[i*w*3+j];
    }
    jpeg_write_scanlines(&cinfo, buffer, 1);
  }

  jpeg_finish_compress(&cinfo);
  jpeg_destroy_compress(&cinfo);
}

