/*
 * board.c
 *
 *  Created on: May 15, 2020
 *      Author: edpiz
 */

#include "board.h"
#include "STM32f103.h"

//Sets the system clock, AHB, and APB2 set to 64Mhz. APB1 set to 32Mhz.
void clockConfig()
{
   RCC->CR |= HSION_ON;                 //Enable internal clock
   while((RCC->CR & (HSIRDY_MASK)) == NOT_READY)
   {
   }  //Wait for internal clock to be ready

   RCC->CFGR |= PLLSRC_HSI |     //Bit 16 cleared to set PLL input to 4Mhz (HSI / 2)
            PLLMUL_CLOCKx16 |    //Multiplication factor of 16 for a clock speed of 64Mhz
            ADP2_PRESCALLER_0 |  //APB2's clock (PCLK2) to run at full speed
            ADP1_PRESCALLER_2 |  //Sets APB1's clock (PCLK1) to run at half speed.  32Mhz
            AHB_PRESCALLER_0;    //AHB runs at full speed

   RCC->CR |= PLLON_ON;                 //turn the PLL on
   while((RCC->CR & PLLRDY_MASK) == NOT_READY)
   {
   } //Wait for PLL to be ready

   FLASH->ACR |= LATENCY_2_WAIT;    //Two wait states, 48 MHz < SYSCLK ≤ 72 MHz

   RCC->CFGR |= SYSTEM_CLOCK_PLL;   //Set the output of the PLL (64Mhz) to be SYSCLK
}

void gpioConfig(void)
{
   //*** PCB LED ***
   //enable clock for GPIO C
   RCC->APB2ENR |= IOPCEN_ENABLE;          //bit number 4 enables clock for gpio C

   GPIOC->CRH |= CNF13_PUSH_PULL_OUT |     //set Port C I/O 13 to output push pull
            MODE13_OUT_2MHZ;               //Set Port C I/O 13 to output @ 2Mhz

   //*** Bread Board LED ***
   //enable clock for GPIO B
   RCC->APB2ENR |= IOPBEN_ENABLE;           //enable GPIO B clock

   //LED active high
   GPIOB->CRL = CNF6_PUSH_PULL_OUT |        //set Port B I/O 6 to output push pull
            MODE6_OUT_2MHZ;                 //Set Port B I/O 6 to output @ 2Mhz

   //LED active high
   GPIOB->CRL |= CNF7_PUSH_PULL_OUT |       //set Port B I/O 7 to output push pull
            MODE7_OUT_2MHZ;                 //Set Port B I/O 7 to output @ 2Mhz

   //Button active high
   GPIOB->CRH = MODE12_IN |
   CNF12_UP_DOWN_IN;

   GPIOB->BRR = (1 << 12);                   //Pull down resistor

   //button active low
   GPIOB->CRH |= MODE13_IN |
   CNF13_UP_DOWN_IN;

   GPIOB->BSRR = (1 << 13);                 //Pull up resistor

   //*** Shift Register Driving Pins ***
   RCC->APB2ENR |= IOPAEN_ENABLE;           //enable GPIO A clock

   GPIOA->CRL = CNF5_PUSH_PULL_OUT |        //Serial Clock
            MODE5_OUT_10MHZ;

   GPIOA->CRL |= CNF6_PUSH_PULL_OUT |          //Register Clock
            MODE6_OUT_10MHZ;

   GPIOA->CRL |= CNF7_PUSH_PULL_OUT |          //Serial data
            MODE7_OUT_10MHZ;

   //*** Decoder Driving Pins ***

   GPIOA->CRH = CNF8_PUSH_PULL_OUT |           //Address 0
            MODE8_OUT_10MHZ;

   GPIOA->CRH |= CNF9_PUSH_PULL_OUT |          //Address 1
            MODE9_OUT_10MHZ;

   GPIOA->CRH |= CNF10_PUSH_PULL_OUT |         //Address 2
            MODE10_OUT_10MHZ;

}

void timr2Config()
{
   //Note:  There is a clock multiplier before the timers on APH1.  Its set to x2 when we choose to divide the clock freq
   //       that enters APH1.  So timer source clock is 36Mhz x 2 = 64Mhz

   RCC->APB1ENR |= TIM2EN_ENABLE;       //Enables clock source for timer 2

   TIM2->CR1 = ARPE_ENABLED |           //Auto reload is buffered.  No idea what this mean
            CMS_EDGE_ALIGNED |          //Edge-aligned
            DIR_UP |                    //Count Up
            OPM_CONTINUOUS |            //Counter doesn't stop counting after an update event
            URS_OVERFLOW |              //Only overflow/underflows can generate an update interrupt or DMA request
            UDIS_ENABLE |               //Update event enabled.
            CEN_COUNTER_ENABLE;         //Counter enabled!  Start counting.

   TIM2->PSC = 64000;        //Set prescaler to max value. 65535
   TIM2->ARR = 2000;          //Timer2 will count up to 1950 and then reset to 0
}

/*
 * Configure Timer 3 and 4 as 1 32bit timer counting at 1Khz.
 * Timer 3 low bytes.  Timer 4 high bytes
 */
void msTimrConfig(void)
{
   RCC->APB1ENR |= TIM3EN_ENABLE;      //Enables clock source for timer 3
   RCC->APB1ENR |= TIM4EN_ENABLE;      //Enables clock source for timer 4

   TIM3->CR1 = ARPE_ENABLED |          //Auto reload is buffered.
            CMS_EDGE_ALIGNED |         //Edge-aligned
            DIR_UP |                   //Count Up
            OPM_CONTINUOUS |           //Counter doesn't stop counting after an update event
            URS_OVERFLOW |             //Only overflow/underflows can generate an update interrupt or DMA request
            UDIS_ENABLE;               //Update event enabled.

   TIM4->CR1 = ARPE_ENABLED |          //Auto reload is buffered.
            CMS_EDGE_ALIGNED |         //Edge-aligned
            DIR_UP |                   //Count Up
            OPM_CONTINUOUS |           //Counter doesn't stop counting after an update event
            URS_OVERFLOW |             //Only overflow/underflows can generate an update interrupt or DMA request
            UDIS_ENABLE;               //Update event enabled.

   TIM3->CR2 |= MMS_UPDATE;            //Master mode.  Rising edge on each update event (over flow)

   TIM4->SMCR |= TS_ITR2 | SMS_EXTERNAL_CLOCK_MODE; //Sets TM3 to trigger TM4; TM4 to external clock

   TIM3->PSC = 64000;                  //Set prescaler to 64000.  This should make our timer tick along at 1ms intervals
   TIM3->ARR = 0xffff;                 //Timer3 will count up to 65535 and then reset to 0

   TIM3->CR1 |= CEN_COUNTER_ENABLE;
   TIM4->CR1 |= CEN_COUNTER_ENABLE;
}

uint32_t GetUpTime()
{
   uint32_t time;

   time = TIM3->CNT;
   time |= TIM4->CNT << 16;

   return time;
}
