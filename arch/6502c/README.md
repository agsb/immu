# IMMU 6502

An implementation of Forth for 6502 ISA, with inner interpreter using minimal indirect thread code and a dictionary made of machine independent vocabularies. 
  
In 2023, the immu Forth was splitted for ISAs: 6502, Atmega328, RiscV

This is the adapted review of Fig-Forth-6502, updated for some 1979, 1983, 2012 standarts, changes:

        FALSE is 0x0000, TRUE is 0xFFFF

        All math as signed 2-complement's, and 0x8000 is Not A Number (NAN). 

        FOR NEXT masks offsets with 0x8000, as Forth-83, and counts down to zero, as eforth

A review of code, changing the inner interpreter to use push-pull and jump-link, with explicit deep-first search.

More details in  [Notes](https://github.com/agsb/immu/blob/main/arch/6502c/Notes.md)

