\ T3XFORTH -- Misc. useful words, to be sorted...
\ Nils M Holm, 2021
\ Public domain / CC0 License

\ Some words require the DOUBLE word set

\ Print number as byte, word, double word
\
: .BYTE ( c -- ) BASE @ >R BINARY 0
  <# # # # # BL HOLD # # # # #> TYPE R> BASE ! SPACE ;

: .WORD ( u -- ) DUP 8 RSHIFT .BYTE .BYTE ;

: .DWORD ( ud -- ) .WORD .WORD ;

\ Dump words/dwords on stack
\
: .STACK ( -- ) S0 SP@ CELL+ = IF EXIT THEN
   S0 SP@ CELL+ DO CR I @ DUP .WORD 6 .R SPACE CELL /LOOP ;

: .DSTACK ( -- ) S0 SP@ 2 CELLS + U< IF EXIT THEN
   S0 SP@ CELL+ DO CR I 2@ 2DUP .DWORD 12 D.R SPACE
   2 CELLS /LOOP ;

\ Print ASCII table
: ASCII ( -- ) 127 32 DO I 8 MOD 0= IF CR THEN  I EMIT SPACE
    HEX I 0 <# # # #> DECIMAL TYPE  3 SPACES  LOOP ;

\ Interpretive IF/THEN
\
: [IF] ( f -- ) 0= IF
    BEGIN BL WORD DUP C@ 0= 0=
      SWAP DUP C@ 1+ $" [THEN]" -TEXT AND WHILE
    REPEAT THEN ; IMMEDIATE

: [THEN] ( -- ) ; IMMEDIATE

\ Cursor addressing for VT100/ANSI
: CURSOR ( x y -- ) 27 EMIT [CHAR] [ EMIT 0 .R [CHAR] ; EMIT
  0 .R [CHAR] H EMIT ;

\ Better PAGE for VT100/ANSI
: CPAGE ( -- ) PAGE 0 0 CURSOR ;

