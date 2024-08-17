# immu

_18/08/2024 I'm doing a full review of those files and MTC_

    See [milliforth-6502](https://github/agsb/milliforth-6502)

_01/05/2024 I'm on vacancy for refresh some ideas_

An implementation of Forth with inner interpreter using minimal indirect thread code and a dictionary made of machine independent vocabularies. 
  
_Only the inner interpreter and vocabularies related to systems, drives and primitives are machine dependent._

The minimal indirect thread code [MITC](https://github.com/agsb/immu/blob/main/The%20words%20in%20MITC%20Forth%20en.pdf) gives to Forth inner interpreter the decision of when use "push and pull" or "jump and link".

More information in [Details](https://github.com/agsb/immu/blob/main/Details.md)

In 2023, the immu Forth was splitted for ISAs: 6502, Atmega328, and RiscV. 

In september, 2023, a better code for MITC was born, using deep-first search.

see a presentation at [the words in MITC](https://github.com/agsb/immu/blob/main/The%20words%20in%20MITC%20Forth%20en.pdf)

## Go Slow

Ideally Forth was two types of words, **primitives**, aka leafs, that does not reference any forth word, and **compounds**, aka twigs, that are a list of references to forth words. 

Usually leafs are CPU/MCU ISA dependents.

For now, immu just does the MITC and primitives: 

        FALSE TRUE AND OR XOR SHR SHL NEGATE INVERT
        0= 0< = < + - UM+ U< U* (UM*) U/ (UM/MOD)
        >R R> R@ SP@ SP! RP@ RP! DROP ?DUP DUP OVER SWAP ROT 
        BRANCH ZBRANCH LIT EXEC JUMP ALIGN 
        0 1 2 4 1+ 2+ 4+ 1- 2- 4- >< (NIBBLE)
        CHAR CHAR+ CHAR- CELL CELL+ CELL-

Some minimal BIOS support for ( in schedule )
      
        KEY?, KEY, EMIT, 
        IO!, IO@, IRQ? ( for read/write devices and interrupts )
        clock, tick ( for timers )
        flash flush ( for read/write flash memory )

For mixed code, not really a good practice ( in schedule ) 

        :code ;code ( for inline assembler )
        
### mixed 

Need a primitive word to allow create new primitives. Something for 'jump to following address' and for 'resume to compound mode', two words.

In Fig-Forth was ;CODE and must be the last piece in a compound word. What about if need be in the middle ?

'Jump-to-following address' is: HERE CELL CELL + + THEN

## Working

I'm requesting for comments about immu, an minimal indirect thread code for forth. 

I welcome your patience.

There are some insights and documentation at
      https://github.com/agsb/immu/tree/main/docs 
      
For known about [Forth Style](http://www.forth.org/forth_style.html)

![image](https://github.com/agsb/immu/blob/main/beach-g681c55cdd_640.jpg)

Imagem de <a href="https://pixabay.com/pt/users/deanmarston-10862868/?utm_source=link-attribution&amp;utm_medium=referral&amp;utm_campaign=image&amp;utm_content=4388135">Dean Marston</a> por <a href="https://pixabay.com/pt/?utm_source=link-attribution&amp;utm_medium=referral&amp;utm_campaign=image&amp;utm_content=4388135">Pixabay</a>
