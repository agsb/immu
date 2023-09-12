
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
;  *  permit persons to whom the Software is furnished to do so, subject to
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
    lda ps + 4, x
    sta ps + 0, x
    lda ps + 5, x
    sta ps + 1, x
    lda ps + 6, x
    sta ps + 2, x
    lda ps + 7, x
    sta ps + 3, x
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
    lda ps + 8, x
    sta ps + 0, x
    lda ps + 9, x
    sta ps + 1, x
    lda ps + 10, x
    sta ps + 2, x
    lda ps + 11, x
    sta ps + 3, x
   ; continue 
    jmp unnest

;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
;
HEADER "D+", "DPLUS", F_LEAP + F_CORE, LEAF
    clc
    lda ps + 4
    adc ps + 0
    sta ps + 4
    lda ps + 5
    adc ps + 1
    sta ps + 5
    lda ps + 6
    adc ps + 2
    sta ps + 6
    lda ps + 7
    adc ps + 3
    sta ps + 7
    ; continue 
    jmp TWODROP

;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
;
HEADER "D-", "DMINUS", F_LEAP + F_CORE, LEAF
    sec
    lda ps + 4
    sbc ps + 0
    sta ps + 4
    lda ps + 5
    sbc ps + 1
    sta ps + 5
    lda ps + 6
    sbc ps + 2
    sta ps + 6
    lda ps + 7
    sbc ps + 3
    sta ps + 7
    ; continue 
    jmp TWODROP
    
;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
; logical !
HEADER "D2*", "DTWOSTAR", F_LEAP + F_CORE, LEAF
    asl ps + 0
    rol ps + 1
    rol ps + 2
    rol ps + 3
    ; continue 
    jmp unnest
    
;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
; logical !
HEADER "D2/", "DTWOSLASH", F_LEAP + F_CORE, LEAF
    lsr ps + 3
    ror ps + 2
    ror ps + 1
    ror ps + 0
    ; continue 
    jmp unnest

;------------------------------------------------------------------------------
; ok ( w1 w2 -- flag )
;
HEADER "D0=", "DZEQU", F_LEAP + F_CORE, LEAF
    lda ps + 0, x
    bne dfalse
    lda ps + 1, x
    bne dfalse
    lda ps + 2, x
    bne dfalse
    lda ps + 3, x
    bne dfalse
dtrue:
    jmp FTRUE
dfalse:
    jmp FFALSE

;------------------------------------------------------------------------------
; ok ( w1 w2 -- flag )
;
HEADER "D0<", "DZLESS", F_LEAP + F_CORE, LEAF
    lda ps + 3, x
    bmi dtrue
    bpl dfalse

;------------------------------------------------------------------------------
; ok ( w1 w2 -- flag )
;
HEADER "DNEGATE", "DNEGATE", F_LEAP + F_CORE, LEAF
    lda #0
    sbc ps + 3, x
    sta ps + 3, x
    lda #0
    sbc ps + 2, x
    sta ps + 2, x

;    alternative, jmp INEG+1

    lda #0
    sbc ps + 1, x
    sta ps + 1, x
    lda #0
    sbc ps + 0, x
    sta ps + 0, x
    ; continue
    jmp unnest

;------------------------------------------------------------------------------
; ok ( w1 w2 -- flag )
;
HEADER "DABS", "DABS", F_LEAP + F_CORE, LEAF
    lda ps + 3, x
    bmi DNEGATE
    ; continue
    jmp unnest
    
;------------------------------------------------------------------------------

