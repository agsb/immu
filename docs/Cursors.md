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
  
|S -> R, S -> I, S -> D, S -> (S), S -> (R), S -> (I), S -> (D),
|R -> S, R -> I, R -> D, R -> (S), R -> (R), R -> (I), R -> (D),
|I -> S, I -> R, I -> D, I -> (S), I -> (R), I -> (I), I -> (D),
|D -> S, D -> R, D -> I, D -> (S), D -> (R), D -> (I), D -> (D),
|(S) -> S, (S) -> R, (S) -> I, (S) -> D, (S) -> (R), (S) -> (I), (S) -> (D),
|(R) -> S, (R) -> R, (R) -> I, (R) -> D, (R) -> (S), (R) -> (I), (R) -> (D),
|(I) -> S, (I) -> R, (I) -> I, (I) -> D, (I) -> (S), (I) -> (R), (I) -> (D),
|(D) -> S, (D) -> R, (D) -> I, (D) -> D, (D) -> (S), (D) -> (R), (D) -> (I),
