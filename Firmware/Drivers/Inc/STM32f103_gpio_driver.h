/*
 * STM32f103_gpio_driver.h
 *
 *  Created on: Jun 3, 2022
 *      Author: edpiz
 */

#ifndef HARDWARE_DRIVERS_STM32F103_GPIO_DRIVER_H_
#define HARDWARE_DRIVERS_STM32F103_GPIO_DRIVER_H_
#include <stdint.h>
#include "gpio_interface.h"
#include "STM32f103.h"

uint8_t gpioHandle_init(Gpio *handle, enum gpioPort port);

#endif /* HARDWARE_DRIVERS_STM32F103_GPIO_DRIVER_H_ */
