#include "xil_printf.h"
#include "sleep.h"
#include "sccb_driver.h"
#include "ov7670_regs.h"
#include "vdma_input.h"

// No cam_ctrl / axi_gpio_0 setup here -- RESET and PWDN are hardwired
// directly to 3.3V / GND on the header, so there's nothing for
// software to drive for those two pins.

int main() {
    xil_printf("Starting OV7670 input pipeline bring-up...\r\n");

    sccb_init();
    usleep(10000);           // let the sensor stabilize after power-up
    xil_printf("Configuring OV7670 registers over SCCB...\r\n");
    ov7670_configure();
    xil_printf("Camera configured.\r\n");

    xil_printf("Starting VDMA S2MM (camera -> DDR3)...\r\n");
    vdma_input_start();
    xil_printf("VDMA started. Entering monitor loop.\r\n");

    while (1) {
        u32 status = vdma_input_get_frame_count();
        xil_printf("VDMA S2MM status reg = 0x%08x\r\n", status);
        sleep(1);
    }

    return 0;
}
