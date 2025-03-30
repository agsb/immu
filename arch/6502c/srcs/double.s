
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
    jmp link

;------------------------------------------------------------------------------
; ok ( w1 w2 -- w1 w2 w1 w2 )
;
HEADER "2DUP", "TWODUP", F_LEAP + F_CORE, LEAF
    dex
    dex
    dex
    dex
    lda spz + 4, x
    sta spz + 0, x
    lda spz + 5, x
    sta spz + 1, x
    lda spz + 6, x
    sta spz + 2, x
    lda spz + 7, x
    sta spz + 3, x
   ; continue 
    jmp link

;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w1 w2 w3 w4 w1 w2 ))
;
HEADER "2OVER", "TWOOVER", F_LEAP + F_CORE, LEAF
    dex
    dex
    dex
    dex
    lda spz + 8, x
    sta spz + 0, x
    lda spz + 9, x
    sta spz + 1, x
    lda spz + 10, x
    sta spz + 2, x
    lda spz + 11, x
    sta spz + 3, x
   ; continue 
    jmp link

;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
;
HEADER "D+", "DPLUS", F_LEAP + F_CORE, LEAF
    clc
    lda spz + 4
    adc spz + 0
    sta spz + 4
    lda spz + 5
    adc spz + 1
    sta spz + 5
    lda spz + 6
    adc spz + 2
    sta spz + 6
    lda spz + 7
    adc spz + 3
    sta spz + 7
    ; continue 
    jmp TWODROP

;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
;
HEADER "D-", "DMINUS", F_LEAP + F_CORE, LEAF
    sec
    lda spz + 4
    sbc spz + 0
    sta spz + 4
    lda spz + 5
    sbc spz + 1
    sta spz + 5
    lda spz + 6
    sbc spz + 2
    sta spz + 6
    lda spz + 7
    sbc spz + 3
    sta spz + 7
    ; continue 
    jmp TWODROP
    
;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
; logical !
HEADER "D2*", "DTWOSTAR", F_LEAP + F_CORE, LEAF
    asl spz + 0
    rol spz + 1
    rol spz + 2
    rol spz + 3
    ; continue 
    jmp link
    
;------------------------------------------------------------------------------
; ok ( w1 w2 w3 w4 -- w w )
; logical !
HEADER "D2/", "DTWOSLASH", F_LEAP + F_CORE, LEAF
    lsr spz + 3
    ror spz + 2
    ror spz + 1
    ror spz + 0
    ; continue 
    jmp link

;------------------------------------------------------------------------------
; ok ( w1 w2 -- flag )
;
HEADER "D0=", "DZEQU", F_LEAP + F_CORE, LEAF
    lda spz + 0, x
    ora spz + 1, x
    bne dfalse
    lda spz + 2, x
    ora spz + 3, x
    bne dfalse
dtrue:
    jmp FTRUE
dfalse:
    jmp FFALSE

;------------------------------------------------------------------------------
; ok ( w1 w2 -- flag )
;
HEADER "D0<", "DZLESS", F_LEAP + F_CORE, LEAF
    lda spz + 3, x
    bmi dtrue
    bpl dfalse

;------------------------------------------------------------------------------
; ok ( w1 w2 -- flag )
;
HEADER "DNEGATE", "DNEGATE", F_LEAP + F_CORE, LEAF
    lda #0
    sbc spz + 3, x
    sta spz + 3, x
    lda #0
    sbc spz + 2, x
    sta spz + 2, x

;    alternative, jmp INEG+1

    lda #0
    sbc spz + 1, x
    sta spz + 1, x
    lda #0
    sbc spz + 0, x
    sta spz + 0, x
    ; continue
    jmp link

;------------------------------------------------------------------------------
; ok ( w1 w2 -- flag )
;
HEADER "DABS", "DABS", F_LEAP + F_CORE, LEAF
    lda spz + 3, x
    bmi DNEGATE
    ; continue
    jmp link  
    
;------------------------------------------------------------------------------

