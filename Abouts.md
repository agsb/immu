# About stacks

When think about words in Forth, some are atomic, and must be a primitive, and some could be a compound. 

An list of atomic's was done by  Mikael Patel as { S@ R@  @ ! nand plus 0= exit }.


# A case of SWAPD

For use onto stacks, there are six { DROP DUP SWAP >R R> R@ } atomics and some that could be derived from those ones.

Lets make a list, to change 3 cells at top (O= is the number of atomic operations) :

![Three Balls](https://github.com/agsb/immu/blob/main/180px-Permutations_RGB.svg.png "Text to show on mouseover")

```
( to create a copy of a cell)
: DUP  ( 1 2 -- 1 2 2 ) ; (O=1)
: DIP  ( 1 2 -- 1 1 2 )  >R DUP >R ; (O=3)
: OVER ( 1 2 -- 1 2 1 ) SWAP DUP >R SWAP R> ; (O=5)
: TUCK ( 1 2 -- 2 1 2 ) DUP >R SWAP R> ; (O=4)

( to destroy a cell)
: DROP ( 1 2 3 -- 1 2 ) ; (O=1)
: NIP  ( 1 2 3 -- 1 3 ) SWAP DROP; (O=2)
: NIPD ( 1 2 3 -- 2 3 ) >R SWAP DROP R>; (O=4) 

( to change the order)
: SWAP ( 1 2 3 -- 1 3 2) ; (O=1)
: SWIP ( 1 2 3 -- 2 1 3 ) >R SWAP R>; (O=3)
: ROT ( 1 2 3 -- 2 3 1 ) >R SWAP R> SWAP; (O=4)
: -ROT ( 1 2 3 -- 3 1 2 ) SWAP >R SWAP R>; (O=4)
: FLIP ( 1 2 3 --  3 2 1 ) SWAP >R SWAP R> SWAP; (O=5)


the sequence { >R DUP R> } or DIP, aka DUPD deprecated in Factor, could be used to { : OVER DUPD SWAP ; } and { : TUCK SWAP DUPD SWAP ; } but DIP does not appear elsewhere.

the sequence { >R SWAP R> } or SWIP, aka SWAPD deprecated in Factor, occurs in { OVER TUCK ROT -ROT FLIP }, if it is a atomic, then could rewrite as:

: TUCK DUP SWIP ; (O=2)
: ROT  SWIP SWAP ; (O=2)
: -ROT SWAP SWIP ; (O=2)
: OVER SWAP DUP SWIP ; (O=3)
: FLIP SWAP SWIP SWAP ; (O=3)

```
As showed, SWIP as atomic is a good choice for design of primitive words.

PS. The permutation of 3 is 6, as { 1 2 3 is initial }, { 1 3 2 is swap }, (2 1 3 is swapd }, { 2 3 1 is rot }, { 3 1 2 is -rot }, { 3 2 1 is flip }

# About OVER

OVER is overrated word, is often used to copy arguments and is also a good choice to be atomic.

# About minimal core set

An list of atomic's was done by Mikael Patel as { S@ R@ @ ! nand plus 0= exit }.

https://github.com/uho/minimal, Ulrich Hoffmann points:

Minimal Forth Workbench: 

    words ALIGNED CELL+ CHAR+ ROT 2/ LSHIFT XOR OR > = 0= TRUE FALSE MOD 2* / * + VARIABLE 
    CONSTANT DUP primitive WORDS INCLUDE bye \ .S ( CR KEY? EMIT KEY DOES> ; CREATE : 
    EXECUTE J LOOP UNTIL AGAIN BEGIN ELSE ' I DO REPEAT WHILE THEN IF R> OVER DROP R@ >R 
    SWAP RSHIFT INVERT AND < - */MOD CHARS CALIGNED CALIGN C@ C, C! CELLS ALIGN @ , ! 

    48 primitives, 69 words ok
