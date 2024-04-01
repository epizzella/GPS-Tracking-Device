#ifndef __PCCOM_H
#define __PCCOM_H

#include "IUartWrapper.hpp"

class PcCom : public IUartWrapper
{
public:
    PcCom();
    UartStatus write(const uint8_t *pData, uint16_t Size) override;
    UartStatus beginRead(uint8_t *pData, uint16_t Size) override;
    void RegisterReceiver(ReceiverPtr receiver) override;
    UartStatus writeBlocking(const uint8_t *pData, uint16_t Size, uint32_t Timeout) override;
    UartStatus readBlocking(uint8_t *pData, uint16_t Size, uint32_t Timeout) override;

private:
    static const uint16_t m_rxBuffSize = 50;
    static const uint16_t m_buffNum = 5;
    uint8_t m_rxBuffer[m_buffNum][m_rxBuffSize] = {};
    uint16_t m_recievedSize;
};

#endif
