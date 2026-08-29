#include "xil_printf.h"
#include "sleep.h"
#include "sccb_driver.h"
#include "ov7670_regs.h"
#include "camera_pipeline.h"

int main() {
    xil_printf("Mini-project: camera -> HDMI, final build\r\n");

    sccb_init();
    usleep(10000);
    ov7670_configure();
    xil_printf("Camera configured.\r\n");

    adv7511_configure();
    xil_printf("ADV7511 configured.\r\n");

    vdma_pipeline_start();
    xil_printf("VDMA (S2MM+MM2S) started. Watch the monitor.\r\n");

    while (1) {
        xil_printf("S2MM status = 0x%08x\r\n", vdma_get_s2mm_status());
        sleep(1);
    }
    return 0;
}