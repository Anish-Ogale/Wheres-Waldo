#include "vdma_input.h"
#include "xaxivdma.h"
#include "xparameters.h"
#include <string.h>   // needed for memset() below

#define VDMA_DEVICE_ID  0
#define FRAME_WIDTH      320   // matches ACTIVE_PIXELS_PER_LINE in ov7670_capture.sv
#define FRAME_HEIGHT     240
#define BYTES_PER_PIXEL  2     // RGB565

static UINTPTR frame_buf[3] = {
    0x10000000,
    0x10100000,
    0x10200000
};

static XAxiVdma vdma;

void vdma_input_start(void) {
    XAxiVdma_Config *cfg = XAxiVdma_LookupConfig(VDMA_DEVICE_ID);
    XAxiVdma_CfgInitialize(&vdma, cfg, cfg->BaseAddress);

    XAxiVdma_DmaSetup s2mm_setup;
    memset(&s2mm_setup, 0, sizeof(s2mm_setup));
    s2mm_setup.VertSizeInput      = FRAME_HEIGHT;
    s2mm_setup.HoriSizeInput      = FRAME_WIDTH * BYTES_PER_PIXEL;
    s2mm_setup.Stride             = FRAME_WIDTH * BYTES_PER_PIXEL;
    s2mm_setup.FrameDelay         = 0;
    s2mm_setup.EnableCircularBuf  = 1;
    s2mm_setup.EnableSync         = 1;
    s2mm_setup.PointNum           = 0;
    s2mm_setup.EnableFrameCounter = 0;
    s2mm_setup.FixedFrameStoreAddr= 0;

    XAxiVdma_DmaConfig(&vdma, XAXIVDMA_WRITE, &s2mm_setup);
    XAxiVdma_DmaSetBufferAddr(&vdma, XAXIVDMA_WRITE, frame_buf);
    XAxiVdma_DmaStart(&vdma, XAXIVDMA_WRITE);
}

u32 vdma_input_get_frame_count(void) {
    return XAxiVdma_GetStatus(&vdma, XAXIVDMA_WRITE);
}