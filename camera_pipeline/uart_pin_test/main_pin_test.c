#include "xil_printf.h"
#include "sleep.h"
#include "xgpio.h"
#include "xparameters.h"
#include "sccb_driver.h"
#include "ov7670_regs.h"

#define MONITOR_GPIO_DEVICE_ID  XPAR_XGPIO_1_BASEADDR
#define DATA_BITS 6
#define DATA_MASK ((1 << DATA_BITS) - 1)

static XGpio monitor_gpio;

int main() {
    xil_printf("Pin verification test - configuring camera...\r\n");
    sccb_init();
    usleep(10000);
    ov7670_configure();
    xil_printf("Camera configured.\r\n");

    int status = XGpio_Initialize(&monitor_gpio, MONITOR_GPIO_DEVICE_ID);
    if (status != XST_SUCCESS) {
        xil_printf("ERROR: monitor GPIO init failed, status=%d\r\n", status);
    }

    XGpio_SetDataDirection(&monitor_gpio, 1, 0xFFFFFFFF); // all inputs
    xil_printf("Point camera at solid WHITE, then solid BLACK, and watch\r\n");
    xil_printf("the 'data' field below settle near max/min each time.\r\n");
    xil_printf("bit layout: [href][vsync][data(%d bits)]\r\n\r\n", DATA_BITS);

    while (1) {
        u32 val = XGpio_DiscreteRead(&monitor_gpio, 1);
        u32 href_bit = (val >> DATA_BITS) & 0x1;
        u32 vsync_bit = (val >> (DATA_BITS+1)) & 0x1;
        u32 data = val & DATA_MASK;
        xil_printf("raw=0x%02x href=%d vsync=%d data=0x%x (%d/%d)\r\n",
                   (unsigned int)val, (int)href_bit, (int)vsync_bit,
                   (unsigned int)data, (unsigned int)data, DATA_MASK);
        usleep(200000);
    }
    return 0;
}