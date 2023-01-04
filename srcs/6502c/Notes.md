# Notes for 6502 IMMU


## 28/12/2022
 
 - sources for use with cc65 in Linux
 - almost adapted from fig-forth-6502, from W. B. Ragsdale
 - changed to use MITC
 - changed to use X and Y as parameter and return
 - minimal use of pages, zero and one, for easy use external libraries
 - all stuff use absolute address and jump 
 - bare minimal use real stack pointer SP 
 - bare minimal use jsr/rts for relative BIOS routines
 - 16 bits pseudo registers (as in SWEET16): DS, RS, T, N, W, C at page zero
 - 8 bits safe registers for A, Y, X, S, P, H at page zero
 - stacks goes downwards, uses X and Y for index
 
 ### I know that will be not the most fastest code possible.  
 
 ( I'm learning the 6502 ISA, there are Tons of technologies to know. )
 
 Most of page zero indexed access uses 3 cycles and absolute indexed access uses 4 cycles.
 Not using Accumulator as Top of Stack, just as accumulator (as is).
 
 
 ### the 6502C pages:
 
             $0000 0x00FF page zero,  reserved for indexed acess
             $0100 0x01FF page one,   reserved for SP use
             
             $0200 0x02FF page two,   data parameter stack, indexed by X, offset wraps
             $0300 0x03FF page three, return address stack, indexed by Y, offset wraps
             
             $0400 0x04FF page four, forth internal registers and buffers 
             $0500 0x0FFF free 3072 bytes SRAM, BIOS buffer0, 
             
             $1000  page forth :)
             
             $8000  start of ROM (FLASH) BIOS, IOS, Forth
             
 ### the indirect access question

    the 6502 ISA offers only LDA (ZP),Y as indirect access
    [ zero page as array, ZP is a index, Y an offset ] 

 ### the MITC inner interpreter

     R> >R R@ must use the second cell at return stack to load/save values
 
 
