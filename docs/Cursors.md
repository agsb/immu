# Cursors

Forth lives in an array, a sequential set of cells, and has four cursors, the parameter stack index (S), the return stack index (R), the instruction pointer (I) and the dictionary index ( D).
  
The S and R are sequential access indices for cells that contain references or values and their values are limited to reserved quantities.
      
The I and D are random access indices for the array of cells, usually the DP points to the next free cell in the set.
     
To describe and evaluate how this works, we need to represent the absolute value of the index and the contents of the cell the index points to, so N is the value of and (N) is the contents of the cell pointed to by N.
    
    S -> R, S -> I, S -> D, S -> (S), S -> (R), S -> (I), S -> (D),
    R -> S, R -> I, R -> D, R -> (S), R -> (R), R -> (I), R -> (D),
    I -> S, I -> R, I -> D, I -> (S), I -> (R), I -> (I), I -> (D),
    D -> S, D -> R, D -> I, D -> (S), D -> (R), D -> (I), D -> (D),
    (S) -> S, (S) -> R, (S) -> I, (S) -> D, (S) -> (R), (S) -> (I), (S) -> (D),
    (R) -> S, (R) -> R, (R) -> I, (R) -> D, (R) -> (S), (R) -> (I), (R) -> (D),
    (I) -> S, (I) -> R, (I) -> I, (I) -> D, (I) -> (S), (I) -> (R), (I) -> (D),
    (D) -> S, (D) -> R, (D) -> I, (D) -> D, (D) -> (S), (D) -> (R), (D) -> (I),
  
Some of these operations are well know, examples are:

Some of these operations are non-sense, examples are:

(D) is the random content of a next free cell, so transfer to any place is just a random result. Its removes all |(D) -> S, (D) -> R, (D) -> I, (D) -> D, (D) -> (S), (D) -> (R), (D) -> (I), | operations.

    move over self:
    x S -> S,x R -> R, x I -> I, x D -> D, x (S) -> (S), x (R) -> (R), x (I) -> (I), x (D) -> (D) 

    move random contents:
    x (D) -> S, x (D) -> R, x (D) -> I, x (D) -> D, x (D) -> (S), x (D) -> (R), x (D) -> (I)

v s@  S -> (S)
v r@ R -> (S)
v dovar I -> (S)
v ? I -> (D)
v here D -> (S)
v s! (S) -> S
v r! (S) -> R
v >r (S) -> (R)
v r> (R) -> (S)
v reset s (I) -> S
v reset r (I) -> R
v ? (I) -> I
v reset d (I) -> D
v docon (I) -> (S)
v jump (I) -> (R)
v dolit (I) -> (D)
v allot (S) -> D
v comma (S) -> (D)
v unnest (R) -> I
v nest I -> (R)
v (S) -> I
v to "value (S) -> (I)

z S -> R
z S -> I
z S -> D
z S -> (R)
z S -> (I)
z S -> (D)
z R -> S
z R -> I
z R -> D
z R -> (R)
z R -> (I)
z R -> (D)
z I -> S
z I -> R
z I -> D
z I -> (I)
z D -> S
z D -> R
z D -> I
z D -> (R)
z D -> (I)
z D -> (D)

z (R) -> S
z (R) -> R
z (R) -> D
z (R) -> (I)
z (R) -> (D)
