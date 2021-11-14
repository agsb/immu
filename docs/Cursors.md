# Cursors

Forth lives in an array, a sequential set of cells, and has four cursors. The parameter stack index S, the return stack index R, the instruction pointer I, and the dictionary index D. Each cursor  points a cell which value is represented by (S), (R), (I), and (D).
  
The S and R are sequential access indexes for cells and their values are limited to reserved ranges. By convention S cells are used for keep parameters and R cells are used to keep for return indexes.
      
The I and D are random access indices for the array of cells, usually I points to a cell to be interpreted and the D points to the next free cell in the set.

Also is used a cursor T, for a terminal input buffer whith only two operations (I) -> T, (T) -> (S).

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

    v reset s (I) -> S, v reset r (I) -> R, v reset d (I) -> D
    
    v next (I) -> I,  v nest I -> (R), v unnest (R) -> I, 

    v s@ S -> (S), v r@ R -> (S), v s! (S) -> S, v r! (S) -> R, v >r (S) -> (R), v r> (R) -> (S)

    v dovar I -> (S), v dodoes I -> (D), v dolit (I) -> (D)

    v  store ! (S) -> (I), v fetch @ (I) -> (S)

    v here D -> (S), v allot (S) -> D, v comma (S) -> (D)

    v branch (I) -> (R), v exec (S) -> I
    

Some of these operations are non-sense, examples are:

    To move over self:
    x S -> S, x R -> R, x I -> I, x D -> D, x (S) -> (S), x (R) -> (R), x (I) -> (I), x (D) -> (D) 

    To move random contents (D) to :
    x (D) -> S, x (D) -> R, x (D) -> I, x (D) -> D, x (D) -> (S), x (D) -> (R), x (D) -> (I)

    To move absolute values between :
    z S -> R, z S -> I, z S -> D, z R -> S, z R -> I, z R -> D, 
    z I -> S, z I -> R, z I -> D, z D -> S, z D -> R, z D -> I

    To copy absolute values to:
    z R -> (R), z R -> (I), z R -> (D), z S -> (R), z S -> (I), z S -> (D), z D -> (R),z D -> (I), z D -> (D)

    Not used
    z (R) -> S, z (R) -> R, z (R) -> D, z (R) -> (D), z (R) -> (I), z  I -> (I)


