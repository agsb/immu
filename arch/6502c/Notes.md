# Notes for 6502 IMMU


## 28/12/2022
 
 - sources for use with cc65 in Linux
 - almost adapted from fig-FORTH-6502 1.02c, by W. F. Ragsdale
 - changed to use MITC
 - changed to use X and Y as index for stacks (parameter and return)
 - minimal use of pages, zero and one, for easy use external libraries
 - all stuff use absolute address and jump 
 - bare minimal use real stack pointer SP 
 - bare minimal use jsr/rts for relative BIOS routines
 - 16 bits pseudo registers (as in SWEET16): DS, RS, T, N, W, C, at page zero
 - 8 bits safe registers for A, Y, X, S, P, H, at page zero
 - stacks goes downwards, uses X and Y for index
 
 ### fig_forth 6502

    listings from 

        http://www.forth.org/fig-forth/fig-forth_6502.pdf

        http://www.forth.org/fig-forth/fig-forth_APPLEII.pdf

 ### I know that will be not the most fastest code possible.  
 
 ( I'm learning the 6502 ISA, there are Tons of technologies to know. )
 
 Most of page zero indexed access uses 3 cycles and absolute indexed access uses 4 cycles.
 Not using Accumulator as Top of Stack, just as accumulator (as is). ** may be changed **
 
 ### the 6502 pages:
 
             $0000 0x00FF page zero,  reserved for indexed access
             $0100 0x01FF page one,   reserved for processor stack use
             
             $0200 0x02FF page 02, data parameter stack, indexed by X, offset wraps
             $0300 0x03FF page 03, return address stack, indexed by Y, offset wraps
             
             $0400 0x04FF page 04, forth variables and buffers 
             $0500 0x0FFF free 3072 bytes SRAM, BIOS buffers, 
             
             $1000  page forth :)
             
             $8000  start of ROM (FLASH) BIOS, IOS, Forth
             
             for reference, a disk sector was 512 bytes, a filesystem block was 4096 bytes, 
             and a forth screen is 16 lines of 64 characters, 1024 bytes;
             
 ### the indirect access question

   the 6502 ISA offers only **LDA (BY),Y** as indirect access, "a byte at address pointed by a address at a address with offset",
   [ use zero page as array of cells, BY is a index, Y an offset, as address (BY,BY+1) and offset Y ] 

 ### the MITC inner interpreter

   R> >R R@ must use the second cell at return stack to load/save values
 
 