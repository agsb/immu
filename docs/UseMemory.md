--this file is still a stub--

# Memory Maps
 
Forth was developed as an application in old computers, where a small ROM keeps the basic input output routines (BIOS) and all memory was mapped in RAM. The applications was loaded from magnetic devices.

Modern computers uses flash and sram memory. Flash memory preserves the content and could be re-writted  at least 10.000 and sram does not preserve contents and could be re-written without limits. 

Flash memory write cycle needs a specific CPU/MCU routine, that erase a pages, copy contents from sram and release a page.

Flash memory is better for static content, and SRAM memory for dynamic content.


### groups

    For a generic Forth system,

| name | type | memory | size | used |
| --- | --- | --- | --- | --- |
| BIOS | static | flash | vary | routines for input/output system |
| SS | dynamic | 18 cells | passing parameters between routines, aka system stack |
| CORE | static | flash | vary | processor specific routines for Forth, aka primitives |
| FORTH | static | flash | vary | generic routines for Forth, aka compounds |
| DS | dynamic | 18 cells | data stack for Forth, aka the parameter data stack |
| RS | dynamic | 18 cells | return stack for Forth, aka return stack |
| TIB | dynamic | 80 bytes | terminal input/output buffer | 
| PAD | dynamic | 32 bytes | scratch area for Forth |
| HLD | dynamic | 32 bytes | scratch area for Forth format numbers | 
| DICIONARY | static | vary | generic routines for Forth, aka dictionary |
| VARS | dynamic | vary | keep values of Forth variables |
| | | | |


