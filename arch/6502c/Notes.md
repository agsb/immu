# Notes for 6502 IMMU

## 30/10/2023

    Made a excursion for make a MINT-6502, good improvements on forth package
    using stacks at zero page indexed by X and 24 deep level. Extra routines for
    print numbers and parse for table of references. Good original Z80 code

    Return to 6502toy in november 2023. The bios is need for forth SBC.

## 30/09/2023

    Made new projet [6502toy](https://github.com/agsb/6502toy/), a minimal 6502 single board computer, for use with M.I.T.C. Forth.

    Found some useful codes for excerpt to BIOS. A version [extended of Wozniac Monitor](https://gist.github.com/BigEd/2760560).

    Refinning bios.s to include some useful routines, including tstc, getc, putc, tick,  

## 26/09/2023

    Clean cc65 compile for imu6502 !

## 22/09/2023

**I was wrong about how indirect index are used in 6502**. 

There are tree indexed modes, [_absolute, Y or X_], [_Y,indirect_] and [_indirect,X_] 

The _indirect,X_ MOV ($n,X) works as a offset of array of pointers, and (($n+X)) uses $n+X in page zero. 

The _Y,indirect_ MOV ($n),Y as a offset from a pointer, and (($n)+Y) uses $n in page zero.
  
The _absolute, Y or X_, uses a memory absolute address to be the bottom of stack and grows upwards as Y or X offsets, eg ($mem + Y);

Where $mem is any fixed memory address and $n is a address in page zero. Page zero is a finite resource.

So _absolute,Y_ and _Y,indirect_ are the choices for make a stack and Forth needs two stacks. Options are:

- Use absolute address for references and offsets in X and Y, for return and parameter stacks. This fixes the stack pointers address and leaves cpu stack pointer for BIOS. Both contents must be copied for multi-task or multi-user. 

- Use _Y,indirect_ and save/load the offsets for return and parameter stacks. The offsets Y and X must be exchanged at every push and pop and leaves cpu stack pointer for BIOS. No need copy stack contents for multi-task or multi-user.

- Use _Y,indirect_ and the cpu stack itself. One stack contents must be copied for multi-tasks or multi-user. That is used by the original FIG-Forth and is not multi-task or multi-user.

In any case the limit of stack is 127 words. Charles H Moore uses stacks of 18 to 21 words. 

Using absolute address indexed by Y and X and each with 21 words, could have six tasks or users, without need to copy stack contents, a good trade-off.

## 18/09/2023

    Remake of MITC inner interpreter, done push-pull and jump-link as explicit deep-first search.

## 30/01/2023

- visiting 6502.org for Forth implementations and hardware tips. 
    a lot of excellence work place.
- going to get chips to make a easy board 6502+SRAM+ROM+6551+6522
    all uptodate devices using ATmegas, for SPI, I2C, A/D, etc
- planning merge of compound words (twigs) from f2u atmega, by using same
    basics stuff

## 10-12/01/2023

 - using cc65 as assembler and linker, learning sintax and caveats
 - start to separate bios.s and immu.s, assigns and macros still in immu.s
 - give 4k at $8000 to $8FFF for I/O devices, 
   using 8 address lines for select and 4 address lines for communication 
 - done U* U/ or UM* UM/MOD
 - more primitives words: UM+ UM< ALIGN >< JUMP LIT EXEC ?DUP 
    LSHL, LSHR, ASHL (2*), ASHR (2/) +! ABS
 - quirks about SO, overflow pin, and words ( < UM< ASHL ASHR ) then 
    using common algorithms (no optimized )

## 08/01/2023

 - working in primitive words: FALSE TRUE 0= 0< = < UM+ + - AND OR XOR NOT  
   DROP DUP OVER >R R> R@ SP@ SP! RP@ RP! BRANCH ZBRANCH 0 1 2 4 CR LF BL 
   @ ! C@ C! CHAR CHAR- CHAR+ CELL CELL- CELL+  
 - extending primitives 1+ 2+ 4+ 1- 2- 4- 
 - working on UM/MOD UM* 
 - using cc65, with it, syntax is extreme sensible
 - include parts of sources from fig-Forth-6502 and 
    from guides from Garth Wilson, http://wilsonminesco.com/

## 28/12/2022
 
 - sources for use with cc65 in Linux
 - almost adapted from fig-FORTH-6502 1.02c, by W. F. Ragsdale
 - changed to use MITC
 - changed to use X and Y as index for stacks (parameter and return)
 - minimal use of pages, zero and one, for easy use external libraries
 - all stuff use absolute address and jump

 - bare minimal use real stack pointer SP 
 - bare minimal use jsr/rts for relative BIOS routines
 - 16 bits pseudo registers (as in SWEET16): TOS, NOS, WRK, at page zero
 - 8 bits safe registers for A, Y, X, S, P, H, at page zero
 - stacks goes downwards, uses X and Y for index
 
 ### fig_forth 6502

    listings from 

        http://www.forth.org/fig-forth/fig-forth_6502.pdf

        http://www.forth.org/fig-forth/fig-forth_APPLEII.pdf

 ### I know that will be not the most fastest code possible.  
 
 ( I'm learning the 6502 ISA, there are Tons of technologies to know. )
 
 Most of page zero indexed access uses 3 cycles, 
 push/pull stack 4 cycles,
 absolute indexed access 4 cycles.

 Not using Accumulator as Top of Stack, just as accumulator (as is). 
 
 ** may be changed **
 
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
             and a forth screen is 16 lines of 64 characters, one block of 1024 bytes;
             
 ### the indirect access question

   the 6502 ISA offers only **LDA (BY),Y** as indirect access, "a byte at address pointed by a address at a address with offset",
   [ use zero page as array of cells, BY is a index, Y an offset, as address (BY,BY+1) and offset Y ] 

 ### the MITC inner interpreter

   R> >R R@ must use the second cell at return stack to load/save values
 
 
