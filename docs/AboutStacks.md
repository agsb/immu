# About stacks

When think about words in Forth, some are atomic, and must be a primitive, and some could be a compound. 

An list of atomic's was done by  Mikael Patel as { S@ R@  @ ! nand plus 0= exit }.

# A case of 3 cells

For use onto stacks, usually there are seven { DROP DUP OVER SWAP >R R> R@ } atomics and some that could be derived from those ones.

Lets make a list, to change 3 cells at top (O= is the number of atomic operations) :

![Three Balls](https://github.com/agsb/immu/blob/main/180px-Permutations_RGB.svg.png "Text to show on mouseover")

```
note: ( left is down, right is up -- result )

Operations: Create, Copy, Destroy

( move between stacks )
: >R ( 1 --   ;   -- 1 ) ; (O=3), create at RS, copy PS to RS, destroy PS 
: R> (   -- 1 ; 1 --   ) ; (O=3), create at PS, copy RS to PS, destroy RS 

( to create a copy of a cell)
: DUP  ( 1 2 -- 1 2 2 ) ; (O=2)
: OVER ( 1 2 -- 1 2 1 ) ; (O=2)
: DIP  ( 1 2 -- 1 1 2 ) OVER SWAP ; (O=5) (aka DUPD, deprecated in Factor)
: TUCK ( 1 2 -- 2 1 2 ) SWAP OVER ; (O=5)

( to destroy a cell)
: DROP ( 1 2 3 -- 1 2 ) ; (O=1)
: NIP  ( 1 2 3 -- 1 3 ) SWAP DROP ; (O=4)
: NIPD ( 1 2 3 -- 2 3 ) >R SWAP DROP R> ; (O=10) 

( to change the order)
: SWAP ( 1 2 3 -- 1 3 2 ) ; (O=3)
: SWIP ( 1 2 3 -- 2 1 3 ) >R SWAP R> ; (O=9 or 3) (aka SWAPD, deprecated in Factor)
: ROT  ( 1 2 3 -- 2 3 1 ) >R SWAP R> SWAP ; (O=12 or 4)
: -ROT ( 1 2 3 -- 3 1 2 ) SWAP >R SWAP R> ; (O=12 or 4)
: FLIP ( 1 2 3 -- 3 2 1 ) SWAP >R SWAP R> SWAP ; (O=15 or 4)

the sequence { >R SWAP R> } or SWIP, occurs in { ROT -ROT FLIP }, if it is a atomic, then could rewrite as:

: ROT  SWIP SWAP ; (O=2)
: -ROT SWAP SWIP ; (O=2)
: FLIP SWAP SWIP SWAP ; (O=3)

```
As showed, SWIP as atomic is a good choice for design of a primitive words.

# About OVER

OVER is used often to copy arguments. Charles Moore prefer it over SWAP, deserves to be atomic and be implemented in assembler.


