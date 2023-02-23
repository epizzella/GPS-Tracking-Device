/*
 * gpio_driver.c
 *
 *  Created on: Jun 2, 2022
 *      Author: edpiz
 */

#include <stdlib.h>
#include "STM32f103_gpio_driver.h"

static void writePort(Gpio *self, uint16_t value)
{
   GPIOx_Map* port = (GPIOx_Map*)self->data;
   port->ODR = value;
}

static void clearPort(Gpio *self)
{
   GPIOx_Map* port = (GPIOx_Map*)self->data;
   port->BSRR = 0xff00;
}

static void togglePort(Gpio *self)
{
   GPIOx_Map* port = (GPIOx_Map*)self->data;
   port->ODR ^= 0xffff;
}

static uint16_t readPort(Gpio *self)
{
   GPIOx_Map* port = (GPIOx_Map*)self->data;
   return port->IDR;
}

static void setBit(Gpio *self, uint8_t bit)
{
   GPIOx_Map* port = (GPIOx_Map*)self->data;
   port->BSRR = 0b1 << bit;
}

static void clearBit(Gpio *self, uint8_t bit)
{
   GPIOx_Map* port = (GPIOx_Map*)self->data;
   port->BSRR = 0b1 << (bit + 16);
}

static void toggleBit(Gpio *self, uint8_t bit)
{
   GPIOx_Map* port = (GPIOx_Map*)self->data;
   port->ODR ^= 0b1 << bit;
}

static uint8_t readBit(Gpio *self, uint8_t bit)
{
   GPIOx_Map* port = (GPIOx_Map*)self->data;
   uint16_t value = port->IDR;
   value >>= bit;
   value &= 0b1;
   return 0;
}

Gpio_Interface stm32f103GpioInterface =
{
   .setPort = writePort,
   .clearPort = clearPort,
   .togglePort = togglePort,
   .readPort = readPort,
   .setBit = setBit, 
   .clearBit = clearBit,
   .toggleBit = toggleBit,
   .readBit = readBit,
};

Gpio gpioF103 =
{
   .interface = &stm32f103GpioInterface,
};

uint8_t gpioHandle_init(Gpio *handle, enum gpioPort port)
{
   if(!handle)
   {
      handle = malloc(sizeof(Gpio));
      if(!handle)
      {
         return 0;
      }
   }

   handle->interface = &stm32f103GpioInterface;
   handle->data = (GPIOx_Map*) port;

   return 1;
}

