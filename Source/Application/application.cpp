#include "application.hpp"
#include "cli.hpp"

void application_main()
{
    PcCom com = PcCom();
    Cli terminal = Cli(&com);

    while(1)
    {
        terminal.process();
    }
}