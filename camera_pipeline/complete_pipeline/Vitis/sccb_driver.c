#include "sccb_driver.h"
#include "sleep.h"
#include "xparameters.h"

#define SCCB_GPIO_DEVICE_ID  0

#define SIOC_BIT 0x1
#define SIOD_BIT 0x2
#define OV7670_WRITE_ADDR 0x42

static XGpio sccb_gpio;

static void sccb_set(u8 sioc, u8 siod) {
    u32 val = (sioc ? SIOC_BIT : 0) | (siod ? SIOD_BIT : 0);
    XGpio_DiscreteWrite(&sccb_gpio, 1, val);
    usleep(2);
}

static void sccb_start(void) {
    sccb_set(1, 1);
    sccb_set(1, 0);
    sccb_set(0, 0);
}

static void sccb_stop(void) {
    sccb_set(0, 0);
    sccb_set(1, 0);
    sccb_set(1, 1);
}

static void sccb_write_byte(u8 data) {
    for (int i = 7; i >= 0; i--) {
        u8 bit = (data >> i) & 1;
        sccb_set(0, bit);
        sccb_set(1, bit);
        sccb_set(0, bit);
    }
    
    sccb_set(0, 0);
    sccb_set(1, 0);
    sccb_set(0, 0);
}

void sccb_init(void) {
    XGpio_Initialize(&sccb_gpio, SCCB_GPIO_DEVICE_ID);
    XGpio_SetDataDirection(&sccb_gpio, 1, 0x0); 
}

void sccb_write_reg(u8 reg, u8 val) {
    sccb_start();
    sccb_write_byte(OV7670_WRITE_ADDR);
    sccb_write_byte(reg);
    sccb_write_byte(val);
    sccb_stop();
    usleep(1000);
}
