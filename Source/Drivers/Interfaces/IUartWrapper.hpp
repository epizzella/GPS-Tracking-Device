#ifndef __ISERIALCOM_H
#define __ISERIALCOM_H

#include <stdint.h>

enum class UartStatus
{
    OK = 0x00U,
    ERROR,
    BUSY,
    TIMEOUT
};

class IUartWrapper {
public:
    using ReceiverPtr = void (*)(const uint8_t *pData, uint16_t size);

    /**
     * @brief Non blocking write.
     * @param pData Pointer to data to write.
     * @param size The amount of data to write in bytes.
     */
    virtual UartStatus write(const uint8_t *pData, uint16_t size) = 0;

    /**
     * @brief Starts a non blocking read.
     * @param pData Pointer to the receiving data buffer.
     * @param size The amount of data to read.
     * @return UartStatus
     */
    virtual UartStatus beginRead(uint8_t *pData, uint16_t size) = 0;

    /**
     * @brief Register a callback for nonblocking read completion.
     * @warning This function is called from the uart ISR.
     * @param receiver The callback function.
     */
    virtual void RegisterReceiver(ReceiverPtr receiver) = 0;

    /**
     * @brief Blocking write
     * @param pData Pointer to data the to write.
     * @param size The amount of data to write in bytes.
     * @param timeout The timeout.
     * @return UartStatus 
     */
    virtual UartStatus writeBlocking(const uint8_t *pData, uint16_t size, uint32_t timeout) = 0;

    /**
     * @brief Block read
     * @param pData Pointer to the receiving data buffer.
     * @param size The amount of data to write in bytes.
     * @param timeout The timeout.
     * @return UartStatus 
     */
    virtual UartStatus readBlocking(uint8_t *pData, uint16_t size, uint32_t timeout) = 0;
};

#endif