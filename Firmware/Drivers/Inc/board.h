/*
 * board.h
 *
 *  Created on: May 15, 2020
 *      Author: edpiz
 */

#ifndef BOARD_H
#define BOARD_H
#include <stdint.h>

void clockConfig(void);
void gpioConfig(void);
void timr2Config(void);

void msTimrConfig(void);
uint32_t GetUpTime(void);

#endif

