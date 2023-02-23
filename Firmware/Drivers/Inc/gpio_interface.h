/*
 * gpio_driver.h
 *
 *  Created on: Jun 2, 2022
 *      Author: edpiz
 */

#ifndef HARDWARE_DRIVERS_GPIO_DRIVER_H_
#define HARDWARE_DRIVERS_GPIO_DRIVER_H_

typedef struct Gpio Gpio;

typedef struct Gpio_Interface
{
   void(*setPort)(Gpio *self, uint16_t value);
   void(*clearPort)(Gpio *self);
   void(*togglePort)(Gpio *self);
   uint16_t(*readPort)(Gpio *self);
   void(*setBit)(Gpio *self, uint8_t bit);
   void(*clearBit)(Gpio *self, uint8_t bit);
   void(*toggleBit)(Gpio *self, uint8_t bit);
   uint8_t(*readBit)(Gpio *self, uint8_t bit);
} Gpio_Interface;

struct Gpio
{
   Gpio_Interface *interface;
   void *data;
};

#endif /* HARDWARE_DRIVERS_GPIO_DRIVER_H_ */
