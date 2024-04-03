
#include "PcCom.hpp"

ReceiverPtr PcCom::m_receiver = 0;

UartStatus PcCom::write(const uint8_t *pData, uint16_t size)
{
    return (UartStatus)HAL_UART_Transmit_IT(&huart2, pData, size);
}

UartStatus PcCom::beginRead(uint8_t *pData, uint16_t size)
{
    return (UartStatus)HAL_UART_Receive_IT(&huart2, pData, size);
}

UartStatus PcCom::writeBlocking(const uint8_t *pData, uint16_t size, uint32_t timeout)
{
    return (UartStatus)HAL_UART_Transmit(&huart2, pData, size, timeout);
}

UartStatus PcCom::readBlocking(uint8_t *pData, uint16_t size, uint32_t timeout)
{
    return (UartStatus)HAL_UART_Receive(&huart2, pData, size, timeout);
}

void PcCom::RegisterReceiver(ReceiverPtr receiver)
{
    m_receiver = receiver;
    HAL_UART_RegisterCallback(&huart2, HAL_UART_RX_COMPLETE_CB_ID, m_rxCallback);
}

void PcCom::UnregisterReceiver()
{
    m_receiver = 0;
    HAL_UART_UnRegisterCallback(&huart2, HAL_UART_RX_COMPLETE_CB_ID);
}

void PcCom::m_rxCallback(UART_HandleTypeDef *huart)
{
    m_receiver();
}
