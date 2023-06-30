MinimalBIOS.md

## functions for BIOS

device protocols USART/I2C/SPI

__must find better names__

| name | does | obs |
| -- | -- | -- |
| boot | cleanup start | |
| setup | initial state parameters | |
| reset | load state parameters | |
| halt  | save state parameters | |
| clock | timer tick counter | depends on interrupt of clock uControler |
| timer | timer tick access | depends on interrupt of clock uControler |
| getch | get a char to a USART/USB | Old reliable protocol |
| putch | put a char to a USART/USB | Old reliable protocol |
| peek | get a byte from a address I/O port | |
| poke | put a byte into a address I/O port | |
| flush | copy a page from SRAM to Flash memory | page size vary uC |
| flash | copy a page from Flash memory to SRAM| page size vary uC |
