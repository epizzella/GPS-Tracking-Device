/*
 * STM32f103.h
 *
 *  Created on: May 8, 2020
 *      Author: edpiz
 */
#include <stdint.h>

#ifndef STM32F103_H_
#define STM32F103_H_

#define RCC_BASE   0x40021000

#define GPIOC_BASE 0x40011000
#define GPIOB_BASE 0x40010C00
#define GPIOA_BASE 0x40010800

enum gpioPort
{
   GPIO_PORT_A = GPIOA_BASE, GPIO_PORT_B = GPIOB_BASE, GPIO_PORT_C = GPIOC_BASE,
};

//STM32f103C8 does not have basic times
#define TIMR7_BASE 0x40001400
#define TIMR6_BASE 0x40001000

//General purpose timers
#define TIMR2_BASE 0x40000000
#define TIMR3_BASE 0x40000400
#define TIMR4_BASE 0x40000800

#define FLASH_MEMORY_INTERFACE_BASE 0x40022000

typedef struct
{
   volatile uint32_t CR;            //Clock control                offset 0x00
   volatile uint32_t CFGR;           //Clock config                 offset 0x04
   volatile uint32_t CIR;            //Clock interrupt              offset 0x08
   volatile uint32_t APB2RSTR;       //APB2 periph reset            offset 0x0C
   volatile uint32_t APB1RSTR;       //APB1 periph reset            offset 0x10
   volatile uint32_t AHBENR;         //AHB periph clock enable      offset 0x14
   volatile uint32_t APB2ENR;        //APB2 periph clock enable     offset 0x18
   volatile uint32_t APB1ENR;        //APB1 periph clock enable     offset 0x1C
   volatile uint32_t BDCR;           //Backup domain control        offset 0x20
   volatile uint32_t CSR;            //Control/status               offset 0x24
} RCC_Map;

typedef struct
{

} AdvTimr_Map;

typedef struct
{
   volatile uint32_t CR1;            //Control                      offset 0x00
   volatile uint32_t CR2;            //Control                      offset 0x04
   volatile uint32_t SMCR;           //Clock interrupt              offset 0x08
   volatile uint32_t DIER;           //DMA/Interrupt enable         offset 0x0C
   volatile uint32_t SR;             //Status                       offset 0x10
   volatile uint32_t EGR;            //Event generation             offset 0x14
   volatile uint32_t CCMR1;          //APB2 periph clock enable     offset 0x18
   volatile uint32_t CCMR2;          //APB1 periph clock enable     offset 0x1C
   volatile uint32_t CCER;           //Backup domain control        offset 0x20
   volatile const uint32_t CNT;       //Counter value                offset 0x24
   volatile uint32_t PSC;            //Prescaler                    offset 0x28
   volatile uint32_t ARR;            //Auto-reload                  offset 0x2c
   volatile const uint32_t RESERVED1; //Reserved                     offset 0x30
   volatile uint32_t CCR1;           //Capture/Compare 1            offset 0x34
   volatile uint32_t CCR2;           //Capture/Compare 2            offset 0x38
   volatile uint32_t CCR3;           //Capture/Compare 3            offset 0x3C
   volatile uint32_t CCR4;           //Capture/Compare 4            offset 0x40
   volatile const uint32_t RESERVED2; //Reserved                     offset 0x44
   volatile uint32_t DCR;            //Capture/Compare 2            offset 0x48
   volatile uint32_t DMAR;           //DMA Address Transfer         offset 0x4C
} GenTimr_Map;

typedef struct
{
   volatile uint32_t CR1;            //Control                      offset 0x00
   volatile uint32_t CR2;            //Control                      offset 0x04
   volatile const uint32_t RESERVED1; //Clock interrupt              offset 0x08
   volatile uint32_t DIER;           //DMA/Interrupt enable         offset 0x0C
   volatile uint32_t SR;             //Status                       offset 0x10
   volatile uint32_t EGR;            //Event generation             offset 0x14
   volatile const uint32_t RESERVED2; //APB2 periph clock enable     offset 0x18
   volatile const uint32_t RESERVED3; //APB1 periph clock enable     offset 0x1C
   volatile const uint32_t RESERVED4; //Backup domain control        offset 0x20
   volatile const uint32_t CNT;       //Counter value                offset 0x24
   volatile uint32_t PSC;            //Prescaler                    offset 0x28
   volatile uint32_t ARR;            //Auto-reload                  offset 0x2c

} BasicTimr_Map;

typedef struct
{
   volatile uint32_t CRL;        //Port config low     offset 0x00
   volatile uint32_t CRH;        //Port config high    offset 0x04
   volatile uint32_t IDR;        //Port input data     offset 0x08
   volatile uint32_t ODR;        //Port output data    offset 0x0C
   volatile uint32_t BSRR;       //Port bit set/rest   offset 0x10
   volatile uint32_t BRR;        //Port bit reset      offset 0x14
   volatile uint32_t LCKR;       //Port config lock    offset 0x18
} GPIOx_Map;

typedef struct
{
   volatile uint32_t ACR;       //Flash Access Control Register
} FlashInterface_Map;

#define NOT_READY 0
#define READY 1

/*************************** R C C  C F G R ***************************/
//PLL Multiplication factor
#define PLLMUL_CLOCKx2  0b0000 << 18
#define PLLMUL_CLOCKx3  0b0001 << 18
#define PLLMUL_CLOCKx4  0b0010 << 18
#define PLLMUL_CLOCKx5  0b0011 << 18
#define PLLMUL_CLOCKx6  0b0100 << 18
#define PLLMUL_CLOCKx7  0b0101 << 18
#define PLLMUL_CLOCKx8  0b0110 << 18
#define PLLMUL_CLOCKx9  0b0111 << 18
#define PLLMUL_CLOCKx10 0b1000 << 18
#define PLLMUL_CLOCKx11 0b1001 << 18
#define PLLMUL_CLOCKx12 0b1010 << 18
#define PLLMUL_CLOCKx13 0b1011 << 18
#define PLLMUL_CLOCKx14 0b1100 << 18
#define PLLMUL_CLOCKx15 0b1101 << 18
#define PLLMUL_CLOCKx16 0b1110 << 18

#define PLLSRC_HSI 0b0 << 16    //HSI osc clock / 2
#define PLLSRC_HSE 0b1 << 16

#define ADP2_PRESCALLER_0    0b000 << 11    //Full Speed
#define ADP2_PRESCALLER_2    0b100 << 11
#define ADP2_PRESCALLER_4    0b101 << 11
#define ADP2_PRESCALLER_8    0b110 << 11
#define ADP2_PRESCALLER_16   0b111 << 11   //Divided by 16

#define ADP1_PRESCALLER_0    0b000 << 8    //Full Speed
#define ADP1_PRESCALLER_2    0b100 << 8
#define ADP1_PRESCALLER_4    0b101 << 8
#define ADP1_PRESCALLER_8    0b110 << 8
#define ADP1_PRESCALLER_16   0b111 << 8   //Divided by 16

#define AHB_PRESCALLER_0    0b0000 << 8    //Full Speed
#define AHB_PRESCALLER_2    0b1000 << 8
#define AHB_PRESCALLER_4    0b1001 << 8
#define AHB_PRESCALLER_8    0b1010 << 8
#define AHB_PRESCALLER_16   0b1011 << 8   //Divided by 16
#define AHB_PRESCALLER_64   0b1100 << 8
#define AHB_PRESCALLER_128  0b1101 << 8
#define AHB_PRESCALLER_256  0b1110 << 8
#define AHB_PRESCALLER_512  0b1111 << 8   //Divided by 215

#define SYSTEM_CLOCK_HSI  0b00 << 0
#define SYSTEM_CLOCK_HSE  0b01 << 0
#define SYSTEM_CLOCK_PLL  0b10 << 0

/*************************** R C C  C R ***************************/
/********************* Clock control register *********************/
#define PLLRDY_MASK 0b1 << 25

#define PLLON_OFF 0b0 << 24
#define PLLON_ON  0b1 << 24

#define HSIRDY_MASK 0b1 << 1

#define HSION_OFF 0b0 << 0
#define HSION_ON  0b1 << 0

/*************************** R C C  A P B 2 E N R ***************************/
/******************* APB2 peripheral clock enable register ******************/

//GPIO Port C
#define IOPCEN_DISABLE 0b0 << 4
#define IOPCEN_ENABLE  0b1 << 4
//GPIO Port B
#define IOPBEN_DISABLE 0b0 << 3
#define IOPBEN_ENABLE  0b1 << 3
//Port A
#define IOPAEN_DISABLE 0b0 << 2
#define IOPAEN_ENABLE  0b1 << 2

/*************************** R C C  A P B 1 E N R ***************************/
/******************* APB1 peripheral clock enable register ******************/

//Timer 4 Clock
#define TIM4EN_DISABLE  0b0 << 2
#define TIM4EN_ENABLE   0b1 << 2

//Timer 3 Clock
#define TIM3EN_DISABLE  0b0 << 1
#define TIM3EN_ENABLE   0b1 << 1

//Timer 2 Clock
#define TIM2EN_DISABLE  0b0 << 0
#define TIM2EN_ENABLE   0b1 << 0

/*************************** G P I O x  C R L ***************************/
/******************* Port configuration register low ******************/

//Port Config
#define CNF7_ANALOG_IN    0b00 << 30
#define CNF7_FLOATING_IN  0b01 << 30
#define CNF7_UP_DOWN_IN   0b10 << 30

#define CNF7_PUSH_PULL_OUT       0b00 << 30
#define CNF7_OPEN_DRAIN_OUT      0b01 << 30
#define CNF7_PUSH_PULL_OUT_ALT   0b10 << 30
#define CNF7_OPEN_DRAIN_OUT_ALT  0b11 << 30

#define CNF6_ANALOG_IN    0b00 << 26
#define CNF6_FLOATING_IN  0b01 << 26
#define CNF6_UP_DOWN_IN   0b10 << 26

#define CNF6_PUSH_PULL_OUT       0b00 << 26
#define CNF6_OPEN_DRAIN_OUT      0b01 << 26
#define CNF6_PUSH_PULL_OUT_ALT   0b10 << 26
#define CNF6_OPEN_DRAIN_OUT_ALT  0b11 << 26

#define CNF5_ANALOG_IN    0b00 << 22
#define CNF5_FLOATING_IN  0b01 << 22
#define CNF5_UP_DOWN_IN   0b10 << 22

#define CNF5_PUSH_PULL_OUT       0b00 << 22
#define CNF5_OPEN_DRAIN_OUT      0b01 << 22
#define CNF5_PUSH_PULL_OUT_ALT   0b10 << 22
#define CNF5_OPEN_DRAIN_OUT_ALT  0b11 << 22

//Mode -- Input or set output speed
#define MODE7_IN         0b00 << 28
#define MODE7_OUT_10MHZ  0b01 << 28
#define MODE7_OUT_2MHZ   0b10 << 28
#define MODE7_OUT_50MHZ  0b11 << 28

#define MODE6_IN         0b00 << 24
#define MODE6_OUT_10MHZ  0b01 << 24
#define MODE6_OUT_2MHZ   0b10 << 24
#define MODE6_OUT_50MHZ  0b11 << 24

#define MODE5_IN         0b00 << 20
#define MODE5_OUT_10MHZ  0b01 << 20
#define MODE5_OUT_2MHZ   0b10 << 20
#define MODE5_OUT_50MHZ  0b11 << 20

/*************************** G P I O x  C R H ***************************/
/******************* Port configuration register high ******************/

//Port Config
#define CNF8_ANALOG_IN           0b00 << 2
#define CNF8_FLOATING_IN         0b01 << 2
#define CNF8_UP_DOWN_IN          0b10 << 2

#define CNF8_PUSH_PULL_OUT       0b00 << 2
#define CNF8_OPEN_DRAIN_OUT      0b01 << 2
#define CNF8_PUSH_PULL_OUT_ALT   0b10 << 2
#define CNF8_OPEN_DRAIN_OUT_ALT  0b11 << 2

#define CNF9_ANALOG_IN           0b00 << 6
#define CNF9_FLOATING_IN         0b01 << 6
#define CNF9_UP_DOWN_IN          0b10 << 6

#define CNF9_PUSH_PULL_OUT       0b00 << 6
#define CNF9_OPEN_DRAIN_OUT      0b01 << 6
#define CNF9_PUSH_PULL_OUT_ALT   0b10 << 6
#define CNF9_OPEN_DRAIN_OUT_ALT  0b11 << 6

#define CNF10_ANALOG_IN          0b00 << 10
#define CNF10_FLOATING_IN        0b01 << 10
#define CNF10_UP_DOWN_IN         0b10 << 10

#define CNF10_PUSH_PULL_OUT      0b00 << 10
#define CNF10_OPEN_DRAIN_OUT     0b01 << 10
#define CNF10_PUSH_PULL_OUT_ALT  0b10 << 10
#define CNF10_OPEN_DRAIN_OUT_ALT 0b11 << 10

#define CNF11_ANALOG_IN          0b00 << 14
#define CNF11_FLOATING_IN        0b01 << 14
#define CNF11_UP_DOWN_IN         0b10 << 14

#define CNF11_PUSH_PULL_OUT      0b00 << 14
#define CNF11_OPEN_DRAIN_OUT     0b01 << 14
#define CNF11_PUSH_PULL_OUT_ALT  0b10 << 14
#define CNF11_OPEN_DRAIN_OUT_ALT 0b11 << 14

#define CNF12_ANALOG_IN          0b00 << 18
#define CNF12_FLOATING_IN        0b01 << 18
#define CNF12_UP_DOWN_IN         0b10 << 18

#define CNF12_PUSH_PULL_OUT      0b00 << 18
#define CNF12_OPEN_DRAIN_OUT     0b01 << 18
#define CNF12_PUSH_PULL_OUT_ALT  0b10 << 18
#define CNF12_OPEN_DRAIN_OUT_ALT 0b11 << 18

#define CNF13_ANALOG_IN          0b00 << 22
#define CNF13_FLOATING_IN        0b01 << 22
#define CNF13_UP_DOWN_IN         0b10 << 22

#define CNF13_PUSH_PULL_OUT      0b00 << 22
#define CNF13_OPEN_DRAIN_OUT     0b01 << 22
#define CNF13_PUSH_PULL_OUT_ALT  0b10 << 22
#define CNF13_OPEN_DRAIN_OUT_ALT 0b11 << 22

//Mode -- Input or set output speed
#define MODE8_IN         0b00 << 0
#define MODE8_OUT_10MHZ  0b01 << 0
#define MODE8_OUT_2MHZ   0b10 << 0
#define MODE8_OUT_50MHZ  0b11 << 0

#define MODE9_IN         0b00 << 4
#define MODE9_OUT_10MHZ  0b01 << 4
#define MODE9_OUT_2MHZ   0b10 << 4
#define MODE9_OUT_50MHZ  0b11 << 4

#define MODE10_IN         0b00 << 8
#define MODE10_OUT_10MHZ  0b01 << 8
#define MODE10_OUT_2MHZ   0b10 << 8
#define MODE10_OUT_50MHZ  0b11 << 8

#define MODE11_IN         0b00 << 12
#define MODE11_OUT_10MHZ  0b01 << 12
#define MODE11_OUT_2MHZ   0b10 << 12
#define MODE11_OUT_50MHZ  0b11 << 12

#define MODE12_IN         0b00 << 16
#define MODE12_OUT_10MHZ  0b01 << 16
#define MODE12_OUT_2MHZ   0b10 << 16
#define MODE12_OUT_50MHZ  0b11 << 16

#define MODE13_IN         0b00 << 20
#define MODE13_OUT_10MHZ  0b01 << 20
#define MODE13_OUT_2MHZ   0b10 << 20
#define MODE13_OUT_50MHZ  0b11 << 20

/*************************** G P I O x  B S R R***************************/
/******************* Port bit set/reset register ******************/

#define BSRR_SET_BIT_0   0b1 << 0
#define BSRR_SET_BIT_1   0b1 << 1
#define BSRR_SET_BIT_2   0b1 << 2
#define BSRR_SET_BIT_3   0b1 << 3
#define BSRR_SET_BIT_4   0b1 << 4
#define BSRR_SET_BIT_5   0b1 << 5
#define BSRR_SET_BIT_6   0b1 << 6
#define BSRR_SET_BIT_7   0b1 << 7
#define BSRR_SET_BIT_8   0b1 << 8
#define BSRR_SET_BIT_9   0b1 << 9
#define BSRR_SET_BIT_10 0b1 << 10
#define BSRR_SET_BIT_11 0b1 << 11
#define BSRR_SET_BIT_12 0b1 << 12
#define BSRR_SET_BIT_13 0b1 << 13
#define BSRR_SET_BIT_14 0b1 << 14
#define BSRR_SET_BIT_15 0b1 << 15

#define BSRR_RESET_BIT_0  0b1 << 16
#define BSRR_RESET_BIT_1  0b1 << 17
#define BSRR_RESET_BIT_2  0b1 << 18
#define BSRR_RESET_BIT_3  0b1 << 19
#define BSRR_RESET_BIT_4  0b1 << 20
#define BSRR_RESET_BIT_5  0b1 << 21
#define BSRR_RESET_BIT_6  0b1 << 22
#define BSRR_RESET_BIT_7  0b1 << 23
#define BSRR_RESET_BIT_8  0b1 << 24
#define BSRR_RESET_BIT_9  0b1 << 25
#define BSRR_RESET_BIT_10 0b1 << 26
#define BSRR_RESET_BIT_11 0b1 << 27
#define BSRR_RESET_BIT_12 0b1 << 28
#define BSRR_RESET_BIT_13 0b1 << 29
#define BSRR_RESET_BIT_14 0b1 << 30
#define BSRR_RESET_BIT_15 0b1 << 31

/*************************** G P I O x  B R R***************************/
/******************* Port bit reset register ******************/

#define BRR_RESET_BIT_0   0b1 << 0
#define BRR_RESET_BIT_1   0b1 << 1
#define BRR_RESET_BIT_2   0b1 << 2
#define BRR_RESET_BIT_3   0b1 << 3
#define BRR_RESET_BIT_4   0b1 << 4
#define BRR_RESET_BIT_5   0b1 << 5
#define BRR_RESET_BIT_6   0b1 << 6
#define BRR_RESET_BIT_7   0b1 << 7
#define BRR_RESET_BIT_8   0b1 << 8
#define BRR_RESET_BIT_9   0b1 << 9
#define BRR_RESET_BIT_10 0b1 << 10
#define BRR_RESET_BIT_11 0b1 << 11
#define BRR_RESET_BIT_12 0b1 << 12
#define BRR_RESET_BIT_13 0b1 << 13
#define BRR_RESET_BIT_14 0b1 << 14
#define BRR_RESET_BIT_15 0b1 << 15

/*************************** F L A S H  A C R ***************************/
#define LATENCY_0_WAIT 0b000 << 0
#define LATENCY_1_WAIT 0b001 << 0
#define LATENCY_2_WAIT 0b010 << 0

/*************************** G E N E R A L  T I M E R  C R 1 ***************************/
#define ARPE DISABLED 0b0 << 7
#define ARPE_ENABLED 0b1 << 7

#define CMS_EDGE_ALIGNED         0b00 << 5
#define CMS_CENTER_ALIGNED_DOWN  0b01 << 5
#define CMS_CENTER_ALIGNED_UP    0b10 << 5
#define CMS_CENTER_ALIGNED_BOTH  0b11 << 5

#define DIR_UP   0b0 << 4
#define DIR_DOWN 0b1 << 4

#define OPM_CONTINUOUS 0b0 << 3
#define OPM_STOPS      0b1 << 3

#define URS_MULTI     0b0 << 2
#define URS_OVERFLOW  0b1 << 2

#define UDIS_ENABLE   0b0 << 1
#define UDIS_DISABLE  0b1 << 1

#define CEN_COUNTER_DISABLE  0b0 << 0
#define CEN_COUNTER_ENABLE   0b1 << 0

/*************************** G E N E R A L  T I M E R  C R 2 ***************************/

#define TI1S_TIMx_CH1 0b0 << 7
#define TI1S_TIMx_CH1_CH2_CH3 0b0 << 7

//Master mode selection
#define MMS_RESET          0b000 << 4
#define MMS_ENABLE         0b001 << 4
#define MMS_UPDATE         0b010 << 4
#define MMS_COMPARE_PULSE  0b011 << 4
#define MMS_COMPARE_OC1REF 0b100 << 4
#define MMS_COMPARE_OC2REF 0b101 << 4
#define MMS_COMPARE_OC3REF 0b110 << 4
#define MMS_COMPARE_OC4REF 0b111 << 4

//Capture/compare DMA selection
#define CCDS_CCX    0b0 << 3
#define CCDS_UPDATE 0b1 << 3

/*************************** G E N E R A L  T I M E R  S M C R ***************************/
/*************************** TIMx slave mode control register ****************************/

//Trigger Selection
#define TS_ITR0     0b000 << 4
#define TS_ITR1     0b001 << 4
#define TS_ITR2     0b010 << 4
#define TS_ITR3     0b011 << 4
#define TS_TI1F_ED  0b100 << 4
#define TS_TI1FP1   0b101 << 4
#define TS_TI2FP2   0b110 << 4
#define TS_ETRF     0b111 << 4

//Slave Mode Selection
#define SMS_DISABLED            0b000 << 0
#define SMS_ENCODER_MODE_1      0b001 << 0    //Counter counts up/down on TI2FP1 edge depending on TI1FP2 level.
#define SMS_ENCODER_MODE_2      0b010 << 0    //Counter counts up/down on TI1FP2 edge depending on TI2FP1 level.
#define SMS_ENCODER_MODE_3      0b011 << 0    //Counter counts up/down on both TI1FP1 and TI2FP2 edges depending on the level of the other input.
#define SMS_RESET_MODE          0b100 << 0
#define SMS_GATED_MODE          0b101 << 0
#define SMS_TRIGGER_MODE        0b110 << 0
#define SMS_EXTERNAL_CLOCK_MODE 0b111 << 0

/*************************** P O I N T E R S ***************************/
#define RCC ((RCC_Map*)(RCC_BASE))

#define GPIOA ((GPIOx_Map*)(GPIOA_BASE))
#define GPIOB ((GPIOx_Map*)(GPIOB_BASE))
#define GPIOC ((GPIOx_Map*)(GPIOC_BASE))

//STM32f103C8 does not have basic times
//#define TIMR6 ((BasicTimr_Map*)(TIMR6_BASE))
//#define TIMR7 ((BasicTimr_Map*)(TIMR7_BASE))

#define TIM2 ((GenTimr_Map*)(TIMR2_BASE))
#define TIM3 ((GenTimr_Map*)(TIMR3_BASE))
#define TIM4 ((GenTimr_Map*)(TIMR4_BASE))

#define FLASH ((FlashInterface_Map*)(FLASH_MEMORY_INTERFACE_BASE))

#endif /* STM32F103_H_ */
