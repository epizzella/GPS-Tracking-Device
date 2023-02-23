/**
 ******************************************************************************
 * @file    main.c
 * @author  Edward Pizzella
 * @brief   Default main function.
 ******************************************************************************
 */

#include <stdint.h>
#include "board.h"
#include "STM32f103_gpio_driver.h"

uint32_t time = 0;
uint32_t lastTime = 0;
uint32_t lastTime2 = 0;
uint32_t counter = 0;

int main(void)
{
   clockConfig();          //Run at 64Mhz
   gpioConfig();           //Configure GPIO Pins
   timr2Config();
   msTimrConfig();         //32 bit mili second timer

   Gpio portA; 
   Gpio portC; 
   gpioHandle_init(&portA, GPIO_PORT_A);
   gpioHandle_init(&portC, GPIO_PORT_C);

   while(1)
   {
      time = GetUpTime();

      //flash led
      if(time - lastTime >= 1000)
      {
		 portC.interface->toggleBit(&portC, 13);
         lastTime = time;
         counter++;
      }
   }
}

