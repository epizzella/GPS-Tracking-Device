#ifndef __ISERIALCOM_H
#define __ISERIALCOM_H

#include <stdint.h>

class IUartWrapper {

public:
    enum class UartStatus
    {
        OK       = 0x00U,
        ERROR    = 0x01U,
        BUSY     = 0x02U,
        TIMEOUT  = 0x03U
    };

    virtual UartStatus write(const uint8_t *pData, uint16_t Size) = 0;
    virtual UartStatus read(uint8_t *pData, uint16_t Size) = 0;
    virtual UartStatus writeBlocking(const uint8_t *pData, uint16_t Size, uint32_t Timeout) = 0;
    virtual UartStatus readBlocking(uint8_t *pData, uint16_t Size, uint32_t Timeout) = 0;
};

#endif