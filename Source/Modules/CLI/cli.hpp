#ifndef __CLI_H
#define __CLI_H

#include <stdint.h>
#include <stdbool.h>
#include "PcCom.hpp"

#define BACK_SPACE 127
#define ENTER 13

//Command Line Interface
class Cli 
{
private:
    static bool cmdReady;
    static void rxCallback();
    static IUartWrapper *m_com;


public:

    Cli(IUartWrapper* com);
    /**
     * @brief Process any commands recived from the CLI
     */
    static void process();
};


#endif