# IMMU 6502

An implementation of Forth for 6502 ISA, with inner interpreter using minimal indirect thread code and a dictionary made of machine independent vocabularies. 
  
_Only the inner interpreter and vocabularies related to systems, drives and primitives are machine dependent._

The minimal indirect thread code [MITC](https://github.com/agsb/f2u/blob/main/small%20MITC%20Forth%20en.pdf) gives to Forth inner interpreter the decision of when use "push and pull" or "jump and link".

More IMMU information in [Details](https://github.com/agsb/immu/blob/main/Details.md)

In 2023, the immu Forth was splitted for ISAs: 6502, Atmega328, RiscV

This is the adapted review of Fig-Forth-6502, updated for some 1979, 1983, 2012 standart

changes:

        FALSE is 0x0000, TRUE is 0xFFFF

        All math as signed 2-complement's, and 0x8000 is Not A Number (NAN). 

        FOR NEXT masks offsets with 0x8000, as Forth-83, and counts down to zero, as eforth

        Still no DO LOOP +LOOP LEAVE CASE OF ENDOF ENDCASE

        
More information in [Notes](https://github.com/agsb/immu/blob/main/srcs/6502c/Notes.md)

![image](https://github.com/agsb/immu/blob/main/beach-g681c55cdd_640.jpg)

Imagem de <a href="https://pixabay.com/pt/users/deanmarston-10862868/?utm_source=link-attribution&amp;utm_medium=referral&amp;utm_campaign=image&amp;utm_content=4388135">Dean Marston</a> por <a href="https://pixabay.com/pt/?utm_source=link-attribution&amp;utm_medium=referral&amp;utm_campaign=image&amp;utm_content=4388135">Pixabay</a>
