--this file is still a stub--

# Memory Maps
 
Forth was developed as an application in old computers, where a small ROM keeps the basic input output routines (BIOS) and all memory was mapped in RAM. The applications was loaded from magnetic devices.

Modern computers uses flash and sram memory. Flash memory preserves the content and could be re-writted  at least 10.000 and sram does not preserve contents and could be re-written without limits. 

Flash memory write cycle needs a specific CPU/MCU routine, that erase a pages, copy contents from sram and release a page.

Flash memory is better for static content, and SRAM memory for dynamic content.

## Classic Map

In PolyForth the memory map 

for a interactive task is 
          LOW RAM [--user dictionary---->|DP------|SP<----SP0|TIB0---->IN----#TIB|------|RP<----RP0|--- user area ---] HIGH RAM

for a non-interative task
          LOW RAM [|SP<----SP0||RP<----RP0|--- user area ---] HIGH RAM

### groups

For a generic Forth system,

| name | type | memory | size | used |
| --- | --- | --- | --- | --- |
| BIOS | static | flash | vary | routines for input/output system |
| SS | dynamic | sram  |18 cells | passing parameters between routines, aka system stack |
| CORE | static | flash | vary | processor specific routines for Forth, aka primitives |
| FORTH | static | flash | vary | generic routines for Forth, aka compounds |
| DS | dynamic | sram | 18 cells | data stack for Forth, aka the parameter data stack |
| RS | dynamic | sram | 18 cells | return stack for Forth, aka return stack |
| TIB | dynamic | sram | 80 bytes | terminal input/output buffer| 
| PAD | dynamic | sram | 84 bytes | scratch area for Forth |
| POB | dynamic | sram | 36 bytes | scratch area for Forth format numbers | 
| DICIONARY | static | vary | vary | generic routines for Forth, aka dictionary |
| VARS | dynamic | sram | vary | keep values of Forth variables |
| | | | |

Notes:
- The values for TIB, PAD, BOB are mininal size, as defined by standart Forth 1994 and Forth 2012;
- The values for stacks are enough, as said by Charles Moore
- About TIB there is a quote, from old days of IBM paper card, " 72 is continue ";

### The dictionary

The dictionary of words is composed by two lists, name and code. In the beginining of Forth, these lists are separate: The name list was a linked list with references to next name and to code of word; The code list is just a sequence of pieces of codes. 

The name list have a format as [reference to next word, size and flags, name of word, reference to code] and code list have no fixed format.

The name list grows backwards from end of free memory and the code list grows from begin from free memory. 

Nowadays those lists are merged as one with [reference to next word, size and flags, name of word, vary code].

If no need of interactive interpretation or compiling...







