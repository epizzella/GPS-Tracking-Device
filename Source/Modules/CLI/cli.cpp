#include "cli.hpp"
#include "PcCom.hpp"

char lineBuffers[2][80];
char* activeReadBuff = lineBuffers[0];
char* activeProccessBuff = lineBuffers[1];
uint8_t lineIndex = 0;
uint8_t processBuffLength = 0;

uint8_t rxBuffer[1];
uint8_t txBuffer[80];

IUartWrapper* Cli::m_com = 0;
bool Cli::cmdReady = false;

Cli::Cli(IUartWrapper* com)
{
    com -> RegisterReceiver(rxCallback);
    com -> beginRead(rxBuffer, sizeof(rxBuffer));
    m_com = com;
}

/**
 * @brief Call periodically to process received commands
 * 
 */
void Cli::process()
{
    if(cmdReady == true)
    {
        //process cmd here

        cmdReady = false;
        m_com -> beginRead(rxBuffer, sizeof(rxBuffer));
    }
}

void Cli::rxCallback()
{
    switch (rxBuffer[0])
    {
        case BACK_SPACE:
        {
            if(lineIndex > 0)
            lineIndex--;
            m_com -> beginRead(rxBuffer, sizeof(rxBuffer));
            break;
        }
        case ENTER:
        {
            //swap read & process buffers to keep reading input from user
            char * tempBuff = activeReadBuff;
            activeReadBuff = activeProccessBuff;
            activeProccessBuff = tempBuff;
            processBuffLength = lineIndex - 1;
            lineIndex = 0;
            cmdReady = true;
            break;
        }
        default:
        {
            activeReadBuff[lineIndex] = rxBuffer[0];
            lineIndex++;
            m_com -> beginRead(rxBuffer, sizeof(rxBuffer));
            break;
        }
    }

    //display to user
    m_com -> write(rxBuffer, sizeof(rxBuffer));
}