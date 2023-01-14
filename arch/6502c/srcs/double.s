
;---------------------------------------------------------------------
; /*
;  *  DISCLAIMER"
;  *
;  *  Copyright © 2020, Alvaro Gomes Sobral Barcellos,
;  *
;  *  Permission is hereby granted, free of charge, to any person obtaining
;  *  a copy of this software and associated documentation files (the
;  *  "Software"), to deal in the Software without restriction, including
;  *  without limitation the rights to use, copy, modify, merge, publish,
;  *  distribute, sublicense, and/or sell copies of the Software, and to
;  *  permit per0ons to whom the Software is furnished to do so, subject to
;  *  the following conditions"
;  *
;  *  The above copyright notice and this permission notice shall be
;  *  included in all copies or substantial portions of the Software.
;  *
;  *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;  *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;  *  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE and
;  *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;  *  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;  *  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;  *
;  */
;
;   LICENSE: http://creativecommons.org/licenses/by-nc-sa/4.0/
;
;------------------------------------------------------------------------------
; ok ( w1 w2 --  )
;
HEADER "2DROP", "TWODROP", F_LEAP + F_CORE, LEAF
    inx
    inx
    inx
    inx
    jmp unnest

;------------------------------------------------------------------------------
; ok ( w1 w2 -- w1 w2 w1 w2 )
;
HEADER "2DUP", "TWODUP", F_LEAP + F_CORE, LEAF
    dex
    dex
    dex
    dex
    lda p0 + 4, x
    sta p0 + 0, x
    lda p0 + 5, x
    sta p0 + 1, x
    lda p0 + 6, x
    sta p0 + 2, x
    lda p0 + 7, x
    sta p0 + 3, x
   ; continue 
    jmp unnest

;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w1 w2 w3 w4 w1 w2 ))
;
HEADER "2OVER", "TWOOVER", F_LEAP + F_CORE, LEAF
    dex
    dex
    dex
    dex
    lda p0 + 8, x
    sta p0 + 0, x
    lda p0 + 9, x
    sta p0 + 1, x
    lda p0 + 10, x
    sta p0 + 2, x
    lda p0 + 11, x
    sta p0 + 3, x
   ; continue 
    jmp unnest

;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
;
HEADER "D+", "DPLUS", F_LEAP + F_CORE, LEAF
    clc
    lda p0 + 4
    adc p0 + 0
    sta p0 + 4
    lda p0 + 5
    adc p0 + 1
    sta p0 + 5
    lda p0 + 6
    adc p0 + 2
    sta p0 + 6
    lda p0 + 7
    adc p0 + 3
    sta p0 + 7
    ; continue 
    jmp TWODROP

;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
;
HEADER "D-", "DMINUS", F_LEAP + F_CORE, LEAF
    sec
    lda p0 + 4
    sbc p0 + 0
    sta p0 + 4
    lda p0 + 5
    sbc p0 + 1
    sta p0 + 5
    lda p0 + 6
    sbc p0 + 2
    sta p0 + 6
    lda p0 + 7
    sbc p0 + 3
    sta p0 + 7
    ; continue 
    jmp TWODROP
    
;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
; logical !
HEADER "D2*", "DTWOSTAR", F_LEAP + F_CORE, LEAF
    asl p0 + 0
    rol p0 + 1
    rol p0 + 2
    rol p0 + 3
    ; continue 
    jmp unnest
    
;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
; logical !
HEADER "D2/", "DTWOSLASH", F_LEAP + F_CORE, LEAF
    lsr p0 + 3
    ror p0 + 2
    ror p0 + 1
    ror p0 + 0
    ; continue 
    jmp unnest

;------------------------------------------------------------------------------
; ok ( w1 w2 -- flag )
;
HEADER "D0=", "DZEQU", F_LEAP + F_CORE, LEAF
    lda p0 + 0, x
    bne dfalse
    lda p0 + 1, x
    bne dfalse
    lda p0 + 2, x
    bne dfalse
    lda p0 + 3, x
    bne dfalse
dtrue:
    jmp FTRUE
dfalse:
    jmp FFALSE

;------------------------------------------------------------------------------
; ok ( w1 w2 -- flag )
;
HEADER "D0<", "DZLESS", F_LEAP + F_CORE, LEAF
    lda p0 + 3, x
    bmi dtrue
    bpl dfalse

;------------------------------------------------------------------------------
; ok ( w1 w2 -- flag )
;
HEADER "DNEGATE", "DNEGATE", F_LEAP + F_CORE, LEAF
    lda #0
    sbc p0 + 3, x
    sta p0 + 3, x
    lda #0
    sbc p0 + 2, x
    sta p0 + 2, x
    lda #0
    sbc p0 + 1, x
    sta p0 + 1, x
    lda #0
    sbc p0 + 0, x
    sta p0 + 0, x
    ; continue
    jmp unnest


