# About swapd

When think about words in Forth, some are atomic, and must be a primitive, and some could be a compound. 

An list of atomic's was done by  Mikael Patel as { S@ R@  @ ! nand plus 0= exit }.

For use onto parameter stack, there are five { DROP DUP SWAP >R R> } atomics and some that could be derived from those ones.

Lets make a list:

```
( to create a copy of a cell)
: DUP ( 1 2 -- 1 2 2 ) ; (O=0)
: OVER ( 1 2 -- 1 2 1 ) SWAP DUP >R SWAP R> ; (O=4)
: TUCK ( 1 2 -- 2 1 2 ) DUP >R SWAP R> ; (O=4)

( to change the order of topmost 3 cells)

: SWAP ( 1 2 3 -- 1 3 2) ; (O=0)
: SWAPD ( 1 2 3 -- 2 1 3 ) >R SWAP R>; (O=3)
: ROT ( 1 2 3 -- 2 3 1 ) >R SWAP R> SWAP; (O=4)
: -ROT ( 1 2 3 -- 3 1 2 ) SWAP >R SWAP R>; (O=4)
: FLIP ( 1 2 3 --  3 2 1 ) SWAP >R SWAP R> SWAP; (O=5)

( to destroy a cell)
: DROP ( 1 2 3 -- 1 2 ) ; (O=0)
: NIP ( 1 2 3 -- 1 3 ) SWAP DROP; (O=2)
: NIPD ( 1 2 3 -- 2 3 ) >R SWAP DROP R>; (O=4) 

Note the sequence { >R SWAP R> } aka SWAPD, occurs in ROT -ROT FLIP OVER TUCK then could rewrite as:

: OVER SWAP DUP SWAPD ;
: TUCK DUP SWAPD ;
: ROT SWAPD SWAP ;
: -ROT SWAP SWAPD ;
: FLIP SWAP SWAPD SWAP ;

```
PS. 
- Could be done as { : OVER >R DUP R> SWAP ; } and { : TUCK SWAP R> DUP R> SWAP ; } but { R> DUP R> SWAP } does not appear elsewhere.
- The permutation of 3 is 6, as { 1 2 3 is initial } , { 1 3 2 is swap }, (2 1 3 is swapd }, { 2 3 1 is rot }, { 3 1 2 is -rot }, { 3 2 1 is flip }

