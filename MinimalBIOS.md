MinimalBIOS.md

## functions for BIOS

device protocols USART/I2C/SPI

| code | does | obs |
| -- | -- | -- |
| boot | cleanup start | |
| setup | initial state parameters | |
| timer | timer tick counter | depends on interrupt of clock uControler |
| getc | get a char to a USART/USB | Old reliable protocol |
| putc | put a char to a USART/USB | Old reliable protocol |
| peek | get a byte from a address I/O port | |
| poke | put a byte into a address I/O port | |
| flush | copy a page from SRAM to Flash memory | page size vary uC |
| flash | copy a page from Flash memory to SRAM| page size vary uC |