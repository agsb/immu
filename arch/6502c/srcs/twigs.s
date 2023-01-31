
/*
 *  DISCLAIMER"
 *
 *  Copyright © 2020, Alvaro Gomes Sobral Barcellos,
 *
 *  Permission is hereby granted, free of charge, to any person obtaining
 *  a copy of this software and associated documentation files (the
 *  "Software"), to deal in the Software without restriction, including
 *  without limitation the rights to use, copy, modify, merge, publish,
 *  distribute, sublicense, and/or sell copies of the Software, and to
 *  permit persons to whom the Software is furnished to do so, subject to
 *  the following conditions"
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 *  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 *  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 *  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 *
 */

; 
; http://forum.6502.org/viewtopic.php?f=9&t=7025
; 
; : INTERPRETER           ( str_addr -- )                    \ Common Forth    FIG
;    FIND                         \ ^ addr f      (f=0 if not found)
;    IF    EXECUTE                \ EXECUTE if word found.
;    ELSE  #INT 0=                \ Else, see if it's a valid number.
;          IF DROP THEN           \ DROP the high cell if not double-precision.
;    THEN  ?STACK         ;
; 
; 
; : COMPILER      ( str_addr -- )
;    FIND  ?DUP           IF      \ TOS<>0 if word was found.
;    0< IF ,  EXIT THEN           \ -1 means not IMMEDIATE , so compile it.
;    EXECUTE  EXIT        THEN    \ Else it's IMMEDIATE , so execute it.
;                                 \ If word was not found, see
;    #INT          IF             \ if string is a valid number.  If a decimal
;    2LITERAL EXIT THEN           \ point was found, make a double literal; else
;    DROP LITERAL         ;       \ drop the high cell and make a single literal.
; 
; 
; : INTERPRET             ( -- )          \     18 CELLS                 SF283-286
;    BEGIN   BL WORD                      \ ^ addr
;       DUP C@ 0<>                        \ ^ addr f
;    WHILE   STATE @                      \ ^ addr f
;       IF COMPILER ELSE INTERPRETER THEN \ ^ empty
;    REPEAT  DROP         ;
; 
; HEADER "INTERPRETER", "INTERPRETER", F_COMMON
; 	.word FIND, IF, EXECUTE, ELSE 
; 	.word NUMBER?, ZEQU, IF, DROP, THEN
; 	.word THEN, QSTACK, ENDS
; 
; HEADER "COMPILE", "COMPILE", F_COMMON
; 	.word FIND, QDUP, IF
; 	.word ZLESS, IF, COMMA, EXIT, THEN
; 	.word EXECUTE, EXIT, THEN
; 	.word QNUMBER, IF, LITERAL, EXIT, THEN
; 	.word ENDS
; 
; HEADER "INTERPRET", "INTERPRET", F_COMMON
; 	.word BEGIN, BL, WORD, DUP, CAT, ZEQU, NEGATE
; 	.word WHILE, STATE, AT
; 	.word IF, COMPILER, ELSE INTERPRETER, THEN
; 	.word REPEAT, DROP, ENDS
; 

: /MOD          ( n1 n2 -- rem quot )   \       SF39-40  F83  ANS
   >R  S>D  R> M/MOD    ;

: U/MOD         ( u1 u2 -- rem quot )   \ My own.  Faster than /MOD if you don't
   0  SWAP  UM/MOD      ;               \ need to deal with negative numbers.

: /             ( n1 n2 -- quot )       \       SF32  F83  ANS
   /MOD  NIP            ;

: U/            ( u1 u2 -- quot )       \ My own.  Faster than / if you don't
   U/MOD NIP            ;               \ need to deal with negative numbers.

: MOD           ( n1 n2 -- rem )        \       SF39-40  F83  ANS
   /MOD  DROP           ;

: UMOD          ( u1 u2 -- rem )        \ My own.  Faster than MOD if you don't
   U/MOD DROP           ;               \ need to deal with negative numbers.

