
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
; great DJB hash, adapted for 16bits
;
; hash = (hash << 5) + str[i]
; for ascii chars in sram, in bytes not cells
; ( a u -- h ) djb hash
;
.equ djbHASH, 5381
HEADER "HASH", "HASH", F_LEAP
    NOOP
    clr _zero_
    ldi nos_low, lo8(djbHASH)
    ldi nos_high, hi8(djbHASH)
    pspull zpm_low, zpm_high

    ; get a char
1:    
    
    cp tos_high, tos_low
    brbs BIT_ZERO, 2f

    ld _work_, Z+
    add nos_low, _work_
    adc nos_high, _zero_

    lsl nos_low
    rol nos_high
    lsl nos_low
    rol nos_high
    lsl nos_low
    rol nos_high
    lsl nos_low
    rol nos_high
    lsl nos_low
    rol nos_high

    sbiw tos_low, 1
    rjmp 1b
    
2:
    movw tos_low, nos_low
    POON

;----------------------------------------------------------------------
;
;   ok  ( -- w)
;
;     ©2000-2021 by Gerhard Schmidt,
;      http://www.avr-asm-tutorial.net/avr_en/apps/random_tn13/random_calc_tn13.html
;
;    seed ~ 0x02A8
;
;     also good seeds
;
;    B167 4A3C 9879 B61E 7B26 
;    A858 1F88 50D5 419D 5537
;    0224 0527 5EB6 1E6D BCDC
;    92FF C206 0ECD 9361 2823
;    BE0B B303 6462 0E4C 3D24
;
HEADER "RANDOM", "RANDOM", F_LEAP
    NOOP
;    load seed
    lds wrk_low, SEED
    lds wrk_high, SEED
;    run magics
    eor wrk_low, wrk_high
    swap wrk_low
    add wrk_high, wrk_low
    movw tos_low, wrk_low
    rjmp _seed

;----------------------------------------------------------------------
;
;   ok ( w -- ) 
;   sets seed for rand
;
HEADER "RAND", "RAND", F_LEAP
    NOOP
    movw wrk_low, tos_low
    pspull tos_low, tos_high
_seed:
    sts SEED, wrk_low
    sts SEED + 1, wrk_high
    POON
    
;----------------------------------------------------------------------
;
;   ok ( w -- u) 
;
HEADER "ABS", "ABS", F_LEAP 
    .word DUP, ZEROLT, ZBRANCH, 2f
    .word NEGATE
2:  .word ENDS

;----------------------------------------------------------------------
;
;   is ( w1 w2 -- w) 
;
HEADER "MAX", "MAX", F_LEAP
    .word TWODUP, LTHAN, ZBRANCH, 2f
	.word SWAP 
2:	.word DROP, ENDS

;----------------------------------------------------------------------
;
;   is ( w1 w2 -- w) 
;
HEADER "MIN", "MIN", F_LEAP
    .word SWAP, MAX, ENDS

;----------------------------------------------------------------------
;
;   is ( w1 w2 w3 -- f ) 
;
HEADER "WITHIN", "WITHIN", F_LEAP
    .word OVER, MINUS, TOR, MINUS, RTO, UMLESS, ENDS

;----------------------------------------------------------------------
;
;	from Dr. Ting eForth
;
;----------------------------------------------------------------------
;
; ok ( commom pass for mul and div)
; 
HEADER "UMPASS", "UMPASS",
    NOOP
    .word DUP, UMPLUS, TOR, TOR, DUP, UMPLUS, RTO, PLUS, ENDS
 
;----------------------------------------------------------------------
;	divides
;----------------------------------------------------------------------
;
; ok ( ud u -- ur uq)
; 
HEADER "UM/MOD", "UMDIVMOD", 
    NOOP
    .word OVER, OVER, UMLESS, ZBRANCH, 8f 
 2: .word NEGATE
	.word LIT, 15, FOR
    .word TOR, UMPASS, DUP
    .word RTO, RAT, SWAP, TOR, UMPLUS, RTO, OR, ZBRANCH, 4f
    .word TOR, DROP, ONEPLUS, RTO, BRANCH, 6f 
4:  .word DROP
6:  .word RTO 
    .word NEXT
    .word DROP, SWAP, ENDS
8:  .word DROP, DROP, DROP, FTRUE, DUP, ENDS

;----------------------------------------------------------------------
;
; ok *
HEADER "M/MOD", "MDIVMOD", F_LEAP
    NOOP
    .word DUP, ZEROLT, DUP, TOR, ZBRANCH, 2f 
    .word NEGATE, TOR, DNEG, RTO
2:  .word TOR, DUP, ZEROLT, ZBRANCH, 4f 
    .word RAT, PLUS
4:  .word RTO, UMDIVMOD, RTO, ZBRANCH, 6f
    .word SWAP, NEGATE, SWAP
6:  .word ENDS

;----------------------------------------------------------------------
;
; ok *
HEADER "/MOD", "DIVMOD", F_LEAP
    NOOP
    .word OVER, ZEROLT, SWAP, MDIVMOD, ENDS

;----------------------------------------------------------------------
;
; ok *
HEADER "MOD", "MOD", F_LEAP
    NOOP
    .word DIVMOD, DROP, ENDS

;----------------------------------------------------------------------
;
; ok *
HEADER "/", "DIV", F_LEAP
    NOOP
    .word DIVMOD, SWAP, DROP, ENDS

;----------------------------------------------------------------------
;	multiplies
;----------------------------------------------------------------------
;
; ok *
HEADER "UM*", "UMSTAR", F_LEAP
    NOOP
    .word ZERO, SWAP
    .word LIT, 15, FOR
    .word UMPASS, RTO, ZBRANCH, 4f
    .word TOR, OVER, UMPLUS, RTO, PLUS
4:  .word NEXT
    .word ROTU, DROP, ENDS 

;----------------------------------------------------------------------
;
; ok *
HEADER "*", "STAR", F_LEAP
    NOOP
    .word UMSTAR, DROP, ENDS

;----------------------------------------------------------------------
;
; ok *
HEADER "M*", "MSTAR", F_LEAP
    NOOP
    .word OVER, OVER, XOR, ZEROLT, TOR, ABS, SWAP, ABS, UMSTAR
    .word RTO, ZBRANCH, 2f
    .word DNEG
2:  .word ENDS

;----------------------------------------------------------------------
;
; ok *
HEADER "*/MOD", "STARDIVMOD", F_LEAP
    NOOP
    .word TOR, MSTAR, TOR, MDIVMOD, ENDS

;----------------------------------------------------------------------
;
; ok *
HEADER "*/", "STARDIV", F_LEAP
    NOOP
    .word STARDIVMOD, SWAP, DROP, ENDS

;----------------------------------------------------------------------
; a 64 bit half number, 7FFF FFFF FFFF FFFF is 9.223.372.036.854.775.807
;----------------------------------------------------------------------
