# Cursors

Forth lives in an array, a sequential set of cells, and have four cursors. The parameter stack index S, the return stack index R, the instruction pointer I, and the dictionary index D. Each cursor points a cell, which contents are represented by (S), (R), (I), and (D).
  
The S and R are sequential access indexes for cells and their values are limited to reserved ranges. By convention, S cells are used for keep parameters and R cells are used for keep return indexes. All stacks are last in, first out.
      
The I and D are random access indexes for the array of cells, usually I points to a any cell to be interpreted and the D always points to the next free cell at the set.

Also is used a cursor T, for a terminal input buffer with only two operations: reset T (I) -> T, load value (T) -> (S).

## Combinations
     
To describe and evaluate how this works, we need to investigate the possible combinations of transfer values between these cell indexes values and cells values pointed by. There are 56 permutations of 8 taken 2 by 2, listed below
    
    S -> R, S -> I, S -> D, S -> (S), S -> (R), S -> (I), S -> (D),
    R -> S, R -> I, R -> D, R -> (S), R -> (R), R -> (I), R -> (D),
    I -> S, I -> R, I -> D, I -> (S), I -> (R), I -> (I), I -> (D),
    D -> S, D -> R, D -> I, D -> (S), D -> (R), D -> (I), D -> (D),
    (S) -> S, (S) -> R, (S) -> I, (S) -> D, (S) -> (R), (S) -> (I), (S) -> (D),
    (R) -> S, (R) -> R, (R) -> I, (R) -> D, (R) -> (S), (R) -> (I), (R) -> (D),
    (I) -> S, (I) -> R, (I) -> I, (I) -> D, (I) -> (S), (I) -> (R), (I) -> (D),
    (D) -> S, (D) -> R, (D) -> I, (D) -> D, (D) -> (S), (D) -> (R), (D) -> (I),
  
## Operations

Some of these operations are well know, examples are:

    reset s (I) -> S, reset r (I) -> R, reset d (I) -> D,  // reset pointers
   
    safe s S -> (I), safe r R -> (I), safe d D -> (I),     // safe state 
    
    next (I) -> I,  nest I -> (R), unnest (R) -> I,       // the inner interpreter of Forth

    s@ S -> (S), r@ R -> (S), s! (S) -> S, r! (S) -> R,   // load and save stacks
    
    >r (S) -> (R), r> (R) -> (S),    // exchange values, return stack and parameter stack                          

    dovar I -> (S), dodoes I -> (D), dolit (I) -> (D), 

    store ! (S) -> (I), fetch @ (I) -> (S),

    here D -> (S), allot (S) -> D, comma (S) -> (D),

    branch (I) -> (R), exec (S) -> I,
    

But some of these operations are non-sense, examples are:

    To move over self: // maybe usefull as no operation :?
    x S -> S, R -> R, I -> I, D -> D, (S) -> (S), (R) -> (R), (I) -> (I), (D) -> (D) 

    To move random contents (D) to :
    x (D) -> S, (D) -> R, (D) -> I, (D) -> D, (D) -> (S), (D) -> (R), (D) -> (I)

    To move absolute values between :
    S -> R, S -> I, S -> D, R -> S, R -> I, R -> D, 
    I -> S, I -> R, I -> D, D -> S, D -> R, D -> I

    To copy absolute values to:
    R -> (R), R -> (D), S -> (R), S -> (D), D -> (R), D -> (D)

    Not used ???
    (R) -> S, (R) -> R, (R) -> D, (R) -> (D), (R) -> (I), I -> (I)

 
