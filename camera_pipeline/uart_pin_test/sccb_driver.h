#ifndef SCCB_DRIVER_H
#define SCCB_DRIVER_H

#include "xgpio.h"

void sccb_init(void);
void sccb_write_reg(u8 reg, u8 val);

#endif
