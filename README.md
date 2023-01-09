# immu

An implementation of Forth with inner interpreter using minimal indirect thread code and a dictionary made of machine independent vocabularies. 
  
_Only the inner interpreter and vocabularies related to systems, drives and primitives are machine dependent._

The minimal indirect thread code [MITC](https://github.com/agsb/f2u/blob/main/small%20MITC%20Forth%20en.pdf) gives to Forth inner interpreter the decision of when use "push and pull" or "jump and link".

More information in [Details](https://github.com/agsb/immu/blob/main/Details.md)

In 2023, the immu Forth was splitted for ISAs: 6502, Atmega328, RiscV

## Go Slow

For now, immu just does the MITC and primitives: FALSE TRUE 0= 0< = < 
AND OR XOR SHR SHL NEGATE INVERT + - UM+ U\* U/ UM/MOD UM<
>R R> R@ SP@ SP! RP@ RP! DROP DUP OVER SWAP ROT BRANCH ZBRANCH LIT 
0 1 2 4 1+ 2+ 4+ 1- 2- 4- CELL CELL+ CELL-

Some minimal BIOS support for KEY?, KEY, EMIT, IO!, IO@, IRQ? 

## Working

I'm requesting for comments about immu, an extended indirect thread code for forth. 

I welcome your patience.

There are some insights and documentation at
      https://github.com/agsb/immu/tree/main/docs 
      
For known about [Forth Style](http://www.forth.org/forth_style.html)

![image](https://github.com/agsb/immu/blob/main/beach-g681c55cdd_640.jpg)

Imagem de <a href="https://pixabay.com/pt/users/deanmarston-10862868/?utm_source=link-attribution&amp;utm_medium=referral&amp;utm_campaign=image&amp;utm_content=4388135">Dean Marston</a> por <a href="https://pixabay.com/pt/?utm_source=link-attribution&amp;utm_medium=referral&amp;utm_campaign=image&amp;utm_content=4388135">Pixabay</a>
