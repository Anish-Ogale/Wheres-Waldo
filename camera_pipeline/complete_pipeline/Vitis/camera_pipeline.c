#include "camera_pipeline.h"
#include "xaxivdma.h"
#include "xiic.h"
#include "sleep.h"
#include "string.h"

#define VDMA_BASEADDR   XPAR_XAXIVDMA_0_BASEADDR
#define IIC_BASEADDR    XPAR_AXI_IIC_HDMI_BASEADDR

#define ADV7511_IIC_ADDR 0x39

#define CAM_WIDTH   320
#define CAM_HEIGHT  240
#define OUT_WIDTH   640
#define OUT_HEIGHT  480
#define BPP         2

static UINTPTR frame_buf[3] = {
    0x10000000,
    0x10100000,
    0x10200000
};

static XAxiVdma vdma;
static XIic iic_hdmi;

void vdma_pipeline_start(void) {
    for (int b = 0; b < 3; b++)
        memset((void*)frame_buf[b], 0x00, OUT_WIDTH * OUT_HEIGHT * BPP);

    XAxiVdma_Config *cfg = XAxiVdma_LookupConfig(VDMA_BASEADDR);
    XAxiVdma_CfgInitialize(&vdma, cfg, cfg->BaseAddress);

    XAxiVdma_DmaSetup s2mm;
    memset(&s2mm, 0, sizeof(s2mm));
    s2mm.VertSizeInput     = CAM_HEIGHT;
    s2mm.HoriSizeInput     = CAM_WIDTH * BPP;
    s2mm.Stride            = OUT_WIDTH * BPP;
    s2mm.EnableCircularBuf = 1;
    s2mm.EnableSync        = 1;
    XAxiVdma_DmaConfig(&vdma, XAXIVDMA_WRITE, &s2mm);
    XAxiVdma_DmaSetBufferAddr(&vdma, XAXIVDMA_WRITE, frame_buf);
    XAxiVdma_DmaStart(&vdma, XAXIVDMA_WRITE);

    XAxiVdma_DmaSetup mm2s;
    memset(&mm2s, 0, sizeof(mm2s));
    mm2s.VertSizeInput     = OUT_HEIGHT;
    mm2s.HoriSizeInput     = OUT_WIDTH * BPP;
    mm2s.Stride            = OUT_WIDTH * BPP;
    mm2s.EnableCircularBuf = 1;
    mm2s.EnableSync        = 1;
    XAxiVdma_DmaConfig(&vdma, XAXIVDMA_READ, &mm2s);
    XAxiVdma_DmaSetBufferAddr(&vdma, XAXIVDMA_READ, frame_buf);
    XAxiVdma_DmaStart(&vdma, XAXIVDMA_READ);
}

u32 vdma_get_s2mm_status(void) {
    return XAxiVdma_ReadReg(vdma.BaseAddr, XAXIVDMA_RX_OFFSET + XAXIVDMA_SR_OFFSET);
}

static void iic_write_reg(u8 reg, u8 val) {
    u8 buf[2] = { reg, val };
    XIic_Send(iic_hdmi.BaseAddress, ADV7511_IIC_ADDR, buf, 2, XIIC_STOP);
    usleep(2000);
}

void adv7511_configure(void) {
    XIic_Config *cfg = XIic_LookupConfig(IIC_BASEADDR);
    XIic_CfgInitialize(&iic_hdmi, cfg, cfg->BaseAddress);
    XIic_Start(&iic_hdmi);

    iic_write_reg(0x41, 0x10);
    iic_write_reg(0x98, 0x03);
    iic_write_reg(0x9A, 0xE0);
    iic_write_reg(0x9C, 0x30);
    iic_write_reg(0x9D, 0x61);
    iic_write_reg(0xA2, 0xA4);
    iic_write_reg(0xA3, 0xA4);
    iic_write_reg(0xE0, 0xD0);
    iic_write_reg(0x15, 0x00);
    iic_write_reg(0x16, 0x30);
    iic_write_reg(0x17, 0x02);
    iic_write_reg(0x18, 0x46);
    iic_write_reg(0xAF, 0x06);
    iic_write_reg(0x40, 0x80);
}