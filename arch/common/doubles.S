

/*
 *  DISCLAIMER
 *
 *  Copyright © 2020, Alvaro Gomes Sobral Barcellos,
 *
 *  Permission is hereby granted, free of charge, to any person obtaining
 *  a copy of this software and associated documentation files (the
 *  "Software"), to deal in the Software without restriction, including
 *  without limitation the rights to use, copy, modify, merge, publish,
 *  distribute, sublicense, and/or sell copies of the Software, and to
 *  permit persons to whom the Software is furnished to do so, subject to
 *  the following conditions:
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
 *  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

;----------------------------------------------------------------------
;
; ok ( w -- w + 4 ) 
;
HEADER "4", "FOUR",
     .word LIT, 4, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w + 4 ) 
;
HEADER "4+", "FOURPLUS",
     .word LIT, 4, PLUS, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w -- w - 4 ) 
;
HEADER "4-", "FOURMINUS",
     .word LIT, 4, MINUS, ENDS 
 

;---------------------------------------------------------------------- 
; 
; ok 2! ( a1 a2 -- w1 w2 ) 
; 
HEADER "2!", "TWOTO", 
    .word SWAP, OVER, TO, CELLPLUS, TO, ENDS 
;---------------------------------------------------------------------- 
; 
; ok 2@ ( a1 a2 -- w1 w2 ) 
; 
HEADER "2@", "TWOAT", 
    .word DUP, CELLPLUS, AT, SWAP, AT, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- ) 
;
HEADER "2>R", "TWOTOR",
     .word SWAP, RTO, RTO, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- ) 
;
HEADER "2R>", "TWORTO",
     .word RTO, RTO, SWAP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- ) 
;
HEADER "2R@", "TWORAT",
     .word RTO, RTO, OVER, OVER, TOR, TOR, SWAP, ENDS
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w1 w2 w1 w2 ) 
;
HEADER "2DROP", "TWODROP",
     .word DROP, DROP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w1 w2 w1 w2 ) 
;
HEADER "2DUP", "TWODUP",
     .word OVER, OVER, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) 
;
HEADER "2SWAP", "TWOSWAP",
     .word ROTU, TOR, ROTU, TOR, ENDS 
     
;----------------------------------------------------------------------
;
; ok ( w1 w2 -- w1 w2 w1 w2 ) 
;
HEADER "2OVER", "TWOOVER",
     .word TOR, TOR, TWODUP, RTO, RTO, TWOSWAP, ENDS 
 
;----------------------------------------------------------------------
;
; ok ( w1 w2 w3 w4 -- w3 w4 w1 w2 ) 
;
HEADER "2ROT", "TWOUROT",
     .word TWOTOR, TWOSWAP, TWORTO, TWOSWAP, ENDS 
     
;----------------------------------------------------------------------
;
; ok ( w1 w2 w3 w4 -- w3 w4 + w1 w2 ) 
;
HEADER "D+", "DPLUS",
     .word TOR, SWAP, TOR, UMPLUS, RTO, RTO, PLUS, PLUS, ENDS 
     
;----------------------------------------------------------------------
;
; ok ( w1 w2 w3 w4 -- w3 w4 - w1 w2 ) 
;
HEADER "D-", "DMINUS",
     .word TOR, SWAP, TOR, UMMINUS, RTO, RTO, MINUS, MINUS, ENDS 
     
;----------------------------------------------------------------------
;
; ok ( w1 w2 w3 w4 -- w3 w4 - w1 w2 ) 
;
HEADER "DNEGATE", "DNEG",
     .word INVERT, TOR, INVERT, ONE, UMPLUS, RTO, PLUS, ENDS 
     
;----------------------------------------------------------------------
;
; ok ( w1 w2 w3 w4 -- w3 w4 - w1 w2 ) 
;
HEADER "DABS", "DABS",
     .word DUP, ZEROLT, ZBRANCH, 2f
     .word DNEG
2:   .word ENDS 
     
;----------------------------------------------------------------------
