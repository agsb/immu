# IMMU 6502

An implementation of Forth for 6502 ISA, with inner interpreter using minimal indirect thread code and a dictionary made of machine independent vocabularies. 
  
In 2023, the immu Forth was splitted for ISAs: 6502, Atmega328, RiscV

This is the adapted review of Fig-Forth-6502, updated for some 1979, 1983, 2012 standart

changes:

        FALSE is 0x0000, TRUE is 0xFFFF

        All math as signed 2-complement's, and 0x8000 is Not A Number (NAN). 

        FOR NEXT masks offsets with 0x8000, as Forth-83, and counts down to zero, as eforth

A review of code, changing the inner interpreter to hold the link reference and a memory map to allow free size of stacks.

## notes

### 22/09/2023

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



