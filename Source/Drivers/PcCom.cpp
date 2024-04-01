
#include "PcCom.hpp"
#include "stm32f1xx_hal.h"
#include "usart.h"

UartStatus PcCom::write(const uint8_t *pData, uint16_t size)
{
    return (UartStatus)HAL_UART_Transmit_IT(&huart2, pData, size);
}

UartStatus PcCom::beginRead(uint8_t *pData, uint16_t size)
{
    return (UartStatus)HAL_UART_Receive_IT(&huart2, pData, size);
}

void PcCom::RegisterReceiver(ReceiverPtr receiver)
{

}

UartStatus PcCom::writeBlocking(const uint8_t *pData, uint16_t size, uint32_t timeout)
{
    return (UartStatus)HAL_UART_Transmit(&huart2, pData, size, timeout);
}

UartStatus PcCom::readBlocking(uint8_t *pData, uint16_t size, uint32_t timeout)
{
    return (UartStatus)HAL_UART_Receive(&huart2, pData, size, timeout);
}
