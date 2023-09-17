MinimalBIOS.md

## functions for BIOS

device protocols USART/I2C/SPI

__must find better names__

| name | does | obs |
| -- | -- | -- |
| boot | cleanup start | |
| turnkey | initial state parameters | |
| reset | load state parameters | |
| halt  | save state parameters | |
| clock | timer tick counter | depends on interrupt of clock uControler |
| timer | timer tick access | depends on interrupt of clock uControler |
| getch | get a char to a USART/USB | Old reliable protocol |
| putch | put a char to a USART/USB | Old reliable protocol |
| getio | get a byte from a address I/O port | |
| putio | put a byte into a address I/O port | |
| flush | copy a page from SRAM to Flash memory | page size vary uC |
| flash | copy a page from Flash memory to SRAM| page size vary uC |
| | | |

More device functions

- getUSB (device),
- putUSB (byte, device),
- getSPI (device),
- putSPI (byte, device),
- getI2C (device),
- putI2C (byte, device),
- getline()
- putline()

Some POSIX

- create_file(),
- remove_file(),
- get_access_file(), 
- set_access_file(), 
- open_file(),
- read_file(),
- write_file(),
- close_file(),

Same for directories as files. Maybe devices also ?



