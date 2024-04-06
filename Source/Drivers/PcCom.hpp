#ifndef __PCCOM_H
#define __PCCOM_H

#include "IUartWrapper.hpp"
#include "usart.h"


class PcCom : public IUartWrapper
{
public:
    UartStatus write(const uint8_t *pData, uint16_t Size) override;
    UartStatus beginRead(uint8_t *pData, uint16_t Size) override;
    UartStatus writeBlocking(const uint8_t *pData, uint16_t Size, uint32_t Timeout) override;
    UartStatus readBlocking(uint8_t *pData, uint16_t Size, uint32_t Timeout) override;
    void RegisterReceiver(ReceiverPtr receiver) override;
    void UnregisterReceiver() override;

private:
    static ReceiverPtr m_receiver;
    static void rxCallback(UART_HandleTypeDef *huart);
    static const uint16_t m_rxBuffSize = 50;
    static const uint16_t m_buffNum = 5;
    uint8_t m_rxBuffer[m_buffNum][m_rxBuffSize] = {};
    uint16_t m_recievedSize;
};

#endif
