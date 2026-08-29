#ifndef CAMERA_PIPELINE_H
#define CAMERA_PIPELINE_H
#include "xil_types.h"
void vdma_pipeline_start(void);
void adv7511_configure(void);
u32  vdma_get_s2mm_status(void);
#endif