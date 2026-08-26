// Targets QVGA (320x240) RGB565, matching ACTIVE_PIXELS_PER_LINE=320
// in your ov7670_capture.sv. No functional changes from earlier version.

#include "ov7670_regs.h"
#include "sccb_driver.h"
#include "xil_types.h"

typedef struct { u8 reg; u8 val; } reg_pair;

static reg_pair ov7670_qvga_rgb565[] = {
    {0x12, 0x80}, // COM7: reset registers to default
    {0x12, 0x14}, // COM7: QVGA output size + RGB format
    {0x11, 0x01}, // CLKRC: internal clock prescaler
    {0x0C, 0x00}, // COM3
    {0x3E, 0x00}, // COM14
    {0x8C, 0x00}, // RGB444: disabled
    {0x04, 0x00}, // COM1
    {0x40, 0xD0}, // COM15: RGB565, full output range
    {0x3A, 0x04}, // TSLB
    {0x14, 0x18}, // COM9: AGC ceiling
    {0x4F, 0xB3}, {0x50, 0xB3}, {0x51, 0x00}, // color matrix coefficients
    {0x52, 0x3D}, {0x53, 0xA7}, {0x54, 0xE4},
    {0x58, 0x9E}, // MTXS: matrix sign bits
    {0x3D, 0xC0}, // COM13: gamma enable
    {0x11, 0x00}, // CLKRC: max pixel clock speed
    {0x17, 0x14}, {0x18, 0x02}, // HSTART / HSTOP
    {0x32, 0x80}, // HREF timing
    {0x19, 0x03}, {0x1A, 0x7B}, // VSTART / VSTOP
    {0x03, 0x0A}, // VREF
    {0x0F, 0x41}, {0xB0, 0x84}, // reserved, recommended by known-good configs
};

#define OV7670_NUM_REGS (sizeof(ov7670_qvga_rgb565) / sizeof(reg_pair))

void ov7670_configure(void) {
    for (unsigned int i = 0; i < OV7670_NUM_REGS; i++) {
        sccb_write_reg(ov7670_qvga_rgb565[i].reg, ov7670_qvga_rgb565[i].val);
    }
}
