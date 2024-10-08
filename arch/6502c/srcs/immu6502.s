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
;---------------------------------------------------------------------

.include "macros.s"

;---------------------------------------------------------------------
;
; pseudo registers, page zero
;
lnk = $E0
wrk = lnk + 2
; lnk + 4 free
; lnk + 6 free
; lnk + 8 free
; copycat registers
a_save = lnk + 10
s_save = lnk + 11
x_save = lnk + 12
y_save = lnk + 13
p_save = lnk + 14
f_save = lnk + 15
;
; x is data stack index
; y is return stack pointer
; 
;---------------------------------------------------------------------
;
;  system bios reserved 16 bytes at $F0
;

.segment "CODE"

;---------------------------------------------------------------------
; parameter stack, $0200, grows backwards 0x00 to 0xFF 
spz = $0400

;---------------------------------------------------------------------
; return stack, $0300, grows backwards 0x00 to 0xFF
rpz = $0500

;---------------------------------------------------------------------
; terminal input buffer, $0400, grows forwards
tib0 = $0600
tz = tib0 + TIB_SIZE

;---------------------------------------------------------------------
;
; ???  leave 3 x buffer for disk 
;
;---------------------------------------------------------------------
; forth boot/reset
void = tz + 0   ; easy zero 
turn = tz + 2   ; routine pos-boot
rest = tz + 4   ; routine pre-reset
warn = tz + 6   ; error/warning level

; forth interpreter 
radx = tz + 10   ; base, radix for numbers
stat = tz + 12   ; state, interpreter state
last = tz + 14   ; latest, link to dictionary latest word
list = tz + 16   ; dp, pointer to dicionary next free cell

; status
csp = tz + 20  ; keep parameter stack ptr
crp = tz + 22  ; keep return stack ptr
hnd = tz + 24  ; handler for throw/catch
hld = tz + 26  ; position in <# #>

; devices
dsk = tz + 30   ; disk number
blk = tz + 32   ; block number (track)
sct = tz + 34   ; sector number
scr = tz + 36   ; screen number

;=====================================================================

.P02

.segment "CODE"

;======================================================================
;
;   words to do...
;
COLD:
    ldx #0
    ldy #0

WARM:

TIME:

TURN:

REST:

QUIT:

_main:

_halt:

;======================================================================
;
; some routines adapted from:
; http://wilsonminesco.com/stacks/StackOps.ASM
;
;---------------------------------------------------------------------
;
;   minimal inner address interpreter, using MITC
;   lnk == caller, wrk == callee
;
;   in minimal ITC, the code only jumps 
;   when first reference is 0x0000
;       that marks all primitives 
;   else does a push to return stack
;
;   Because there is few primitives than compound words, 
;   that does a option for inner interpreter by:
;   shorten all compounds words one cell,
;   no dependence of IP to hold next serial reference,
;   easy for MCus or CPUs with separate code and data memory,
;   on RiscV ISA does fast inner code
;
;   all return stack operations must be done 
;   exclusively with >R R> R@
;
;   CELL is 2-bytes
;
;   Using stacks at absolute address.
;
;   rpz top of return stack, y index
;   spz top of parameter stack, x index
;
;   both stacks limited to 128 cells
;
;   the processor sp and page one ($0100) are reserved for BIOS.
;
;   word  lnk, wrk, tos, nos, are pseudo 16 registers at page zero
;   bytes a_save, s_save, x_save, y_save, p_save keep 6502 registers values
;
;   use of jumps for reduce code size;
;   minimal use of JSR/RTS, PHA, PLA;
;   minimal use of page zero;
;   acumulator used as is.
;
;   forth stacks grows backwards !
;
;   spz, x   parameter stack
;   rpz, y   return stack
;
;   ATT: KEEP THE WORDS AT BRANCH OFFSETS (-127 to +127) or COLAPSE
;
HEADER "ENDS", "ENDS", F_LEAP, LEAF
unnest:  ; aka semis:
    ; pull from return stack
    lda rpz, y
    sta wrk + 1
    iny
    lda rpz, y
    sta wrk + 0
    iny

next:
    ; as is, classic ITC from fig-forth 6502
    ; does not need compare low byte
    ; save index
    sty y_save
    ldy #0
    lda (wrk), y
    sta lnk + 0
    ldy #1
    lda (wrk), y
    sta lnk + 1
    ; load index
    ldy y_save

    ; pointer to next reference
    ; CELL is 2 bytes
    clc
    inc wrk + 0
    inc wrk + 0
    bne @end
    inc wrk + 1
@end:

leaf:
    ; in MICT, all leafs start with NULL 0x0000
    ; in 6502, none code at page zero
    ; then just compare high byte
    lda #0
    cmp lnk + 1
    beq jump

nest:   
    ; aka docol
    ; push into return stack
    dey 
    lda wrk + 0
    sta rpz, y
    dey
    lda wrk + 1
    sta rpz, y

link:
    ; next reference
    lda lnk + 0
    sta wrk + 0
    lda lnk + 1
    sta wrk + 1
    jmp next

jump:
    ; pull from return stack
    lda rpz, y
    sta lnk + 0
    iny
    lda rpz, y
    sta lnk + 1
    iny
    ; do the jump
    jmp (wrk)

;---------------------------------------------------------------------

; 
; ok ( -- )
;
HEADER "NOP", "NOOP", F_LEAP, LEAF
    jmp link

;---------------------------------------------------------------------
; 
; ok ( -- false )
;
HEADER "FALSE", "FFALSE", F_LEAP + F_CORE, LEAF
    lda #$00
    jmp fflag

;---------------------------------------------------------------------
; 
; ok ( -- true )
;
HEADER "TRUE", "FTRUE", F_LEAP + F_CORE, LEAF
    lda #$FF
    jmp fflag

;---------------------------------------------------------------------
;
; ok flags are 0x0000 and 0xFFFF
;
fflag:
    dex
    sta spz, x
    dex
    sta spz, x
    ; continue
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w -- false | true ) \ test w = 0
;
HEADER "0=", "ZEQU", F_LEAP + F_CORE, LEAF
    lda spz, x
    inx
    ora spz, x
    inx
    bne FFALSE
    beq FTRUE

;---------------------------------------------------------------------
; 
; ok ( w -- false | true ) \ test w < 0
;
HEADER "0<", "ZLESS", F_LEAP + F_CORE, LEAF
    ; lda spz, x
    inx
    lda spz, x
    inx
    bmi FTRUE
    bpl FFALSE

;---------------------------------------------------------------------
; 
false2:
    dex
    dex

;---------------------------------------------------------------------
; 
false1:
    dex
    dex
    jmp FFALSE

;---------------------------------------------------------------------
; 
true2:
    dex
    dex

;---------------------------------------------------------------------
; 
true1:
    dex
    dex
    jmp FTRUE

;---------------------------------------------------------------------
;
; ok ( w1 w2  -- false | true ) \ test w1 > w2
;
HEADER "=", "EQU", F_LEAP + F_CORE, LEAF
    lda spz + 0, x
    cmp spz + 2, x
    bne false2
    lda spz + 1, x
    cmp spz + 3, x
    bne false2
    beq true2 

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- false | true ) \ test w1 < w2
; look no overflow, SO pin free 
HEADER "<", "LESS", F_LEAP + F_CORE, LEAF
    lda spz + 1, x
    eor #$80
    sta a_save
    lda spz + 3, x
    eor #$80
    cmp a_save
    bcc true2
    bne false2
    lda spz + 0, x
    cmp spz + 2, x
    bcc true2
    bcs false2

;---------------------------------------------------------------------
;
;   ok  ( w1 w2 -- flag ) \ w1 < w2 
;
HEADER "U<", "UMLESS", F_LEAP + F_CORE, LEAF
    lda spz + 1, x
    cmp spz + 3, x
    bcc true2
    bne false2
    lda spz + 0, x
    cmp spz + 2, x
    bcc true2
    bcs false2

;---------------------------------------------------------------------
;
;   ok  ( w1 w2 -- w3 carry )
;
HEADER "U+", "UMPLUS", F_LEAP + F_CORE, LEAF
    clc
    lda spz + 2, x
    adc spz + 0, x
    sta spz + 2, x
    lda spz + 3, x
    adc spz + 1, x
    sta spz + 3, x
    ; save carry flag
    lda #0
    sta spz + 1, x
    adc #0
    sta spz + 0, x
    ; continue
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w1 -- w2 ) \  rotate right
;
HEADER "SHR", "LSHR", F_LEAP + F_CORE, LEAF
    lsr spz + 1, x
    ror spz + 0, x
    ; continue
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w1 -- w2 ) \  rotate left
;
HEADER "SHL", "LSHL", F_LEAP + F_CORE, LEAF
    asl spz + 0, x
    rol spz + 1, x
    ; continue
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w1 -- w2 ) \  rotate right
; by book
HEADER "2/", "ASHR", F_LEAP + F_CORE, LEAF
    ; copy sign bit
    lda spz + 1, x
    and #$80
    sta a_save
    ; shift
    lsr spz + 1, x
    ror spz + 0, x
    ; mask sign bit
    lda spz + 1, x
    ora a_save
    sta spz + 1, x
    ; continue
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w1 -- w2 ) \  rotate right
; by book
HEADER "2*", "ASHL", F_LEAP + F_CORE, LEAF
    ; copy sign bit
    lda spz + 1, x
    and #$80
    sta a_save
    ; shift
    asl spz + 0, x
    rol spz + 1, x
    ; mask sign bit
    lda spz + 1, x
    ora a_save
    sta spz + 1, x
    ; continue
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w1 -- w2 ) \  NOT w1 
;
HEADER "INVERT", "IINV", F_LEAP + F_CORE, LEAF
    lda #$FF
    eor spz + 0, x
    sta spz + 0, x
    eor spz + 1, x
    sta spz + 1, x
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w1  -- w3 ) \  0x00 - w1
;
HEADER "NEGATE", "INEG", F_LEAP + F_CORE, LEAF
    sec
    lda #0
    sbc spz + 1, x
    sta spz + 1, x
    lda #0
    sbc spz + 0, x
    sta spz + 0, x
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- w3 ) \  w1 + w2
;
HEADER "+", "PLUS", F_LEAP + F_CORE, LEAF
    clc
    lda spz + 2, x
    adc spz + 0, x
    sta spz + 2, x
    lda spz + 3, x
    adc spz + 1, x
    sta spz + 3, x
    jmp DROP

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- w3 ) \  w1 - w2
;
HEADER "-", "MINUS", F_LEAP + F_CORE, LEAF
    sec
    lda spz + 2, x
    sbc spz + 0, x
    sta spz + 2, x
    lda spz + 3, x
    sbc spz + 1, x
    sta spz + 3, x
    jmp DROP

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- w3 ) \  w1 AND w2
;
HEADER "AND", "IAND", F_LEAP + F_CORE, LEAF
    lda spz + 2, x
    and spz + 0, x
    sta spz + 2, x
    lda spz + 3, x
    and spz + 1, x
    sta spz + 3, x
    jmp DROP

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- w3 ) \  w1 OR w2
;
HEADER "OR", "IOR", F_LEAP + F_CORE, LEAF
    lda spz + 2, x
    ora spz + 0, x
    sta spz + 2, x
    lda spz + 3, x
    ora spz + 1, x
    sta spz + 3, x
    jmp DROP

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- w3 ) \  w1 XOR w2
;
HEADER "XOR", "IXOR", F_LEAP + F_CORE, LEAF
    lda spz + 2, x
    eor spz + 0, x
    sta spz + 2, x
    lda spz + 3, x
    eor spz + 1, x
    sta spz + 3, x
    jmp DROP

;---------------------------------------------------------------------
; 
; ok ( w -- ) \  
;
HEADER "DROP", "DROP", F_LEAP + F_CORE, LEAF
    inx
    inx
    ; continue
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w -- w w ) \  
;
HEADER "?DUP", "QDUP", F_LEAP + F_CORE, LEAF
    lda spz + 0, x
    ora spz + 1, x
    bne @nodup
    jmp DUP
@nodup:
    jmp link

;---------------------------------------------------------------------
; ok ( w -- w w ) \  
;
HEADER "DUP", "DUP", F_LEAP + F_CORE, LEAF
    dex
    dex
    lda spz + 2, x
    sta spz + 0, x
    lda spz + 3, x
    sta spz + 1, x
    ; continue
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w1 w2 -- w1 w2 w1 ) \  
;
HEADER "OVER", "OVER", F_LEAP + F_CORE, LEAF
    dex
    dex
    lda spz + 4, x
    sta spz + 0, x
    lda spz + 5, x
    sta spz + 1, x
    ; continue
    jmp link

;---------------------------------------------------------------------
;
;   ok  ( w1 --  )
;
HEADER "SP!", "PSTO", F_LEAP + F_CORE, LEAF
    lda spz + 0, x
    tax
    jmp DROP 

;---------------------------------------------------------------------
;
;   ok  ( -- wrk )
;
HEADER "RP!", "RSTO", F_LEAP + F_CORE, LEAF
    lda spz + 0, x
    tay
    jmp DROP

;---------------------------------------------------------------------
;
;   ok  ( w -- ; -- w )
;   yes, must be placed into second on stack
;
HEADER ">R", "TOR", F_LEAP + F_CORE, LEAF
    dey
    dey
    ; move values
    lda spz + 0, x
    sta rpz + 0, y
    lda spz + 1, x
    sta rpz + 1, y
    inx
    inx
    ; continue
    jmp link

;---------------------------------------------------------------------
;
;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R>", "RTO", F_LEAP + F_CORE, LEAF
    dex
    dex
    ; move values
    lda rpz + 0, y
    sta spz + 0, x
    lda rpz + 1, y
    sta spz + 1, x
    iny
    iny
    ; continue
    jmp link

;---------------------------------------------------------------------
;
;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R@", "RAT", F_LEAP + F_CORE, LEAF
    ; move values
    dex
    dex
    lda rpz + 0, y
    sta spz + 0, x
    lda rpz + 1, y
    sta spz + 1, x
    ; continue
    jmp link

;---------------------------------------------------------------------
;
;   ok  ( -- w )
;
HEADER "SP@", "PSAT", F_LEAP + F_CORE, LEAF
    txa
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- wrk )
;
HEADER "RP@", "RSAT", F_LEAP + F_CORE, LEAF
    tya
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- 0 )
;
HEADER "0", "ZERO", F_LEAP + F_CORE, LEAF
    lda #0
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- 1 )
;
HEADER "1", "ONE", F_LEAP + F_CORE, LEAF
    lda #1
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- 2 )
;
HEADER "2", "TWO", F_LEAP + F_CORE, LEAF
    lda #2
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- 3 )
;
HEADER "3", "TRI", F_LEAP + F_CORE, LEAF
    lda #3
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- 4 )
;
HEADER "4", "FOUR", F_LEAP + F_CORE, LEAF
    lda #4
    jmp stor

;---------------------------------------------------------------------
;
;   push with msb cleared
;
stor:
    dex
    dex
    sta spz + 0, x
    ; clear msb
    lda #0
    sta spz + 1, x
    ; continue
    jmp link

;---------------------------------------------------------------------
;
;   ok  ( -- CR )   \ ascii carriage return
;
HEADER "CR", "CR", F_LEAP + F_CORE, LEAF
    lda #13
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- LF )   \ ascii line feed
;
HEADER "LF", "LF", F_LEAP + F_CORE, LEAF
    lda #10
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- BS)   \ ascii backspace
;
HEADER "BS", "BS", F_LEAP + F_CORE, LEAF
    lda #8 
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- HT)   \ ascii horizontal tab
;
HEADER "HT", "HT", F_LEAP + F_CORE, LEAF
    lda #9 
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- VT)   \ ascii vertical tab
;
HEADER "VT", "VT", F_LEAP + F_CORE, LEAF
    lda #11
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- BL )   \ ascii blank space
;
HEADER "BL", "BL", F_LEAP + F_CORE, LEAF
    lda #32
    jmp stor

;---------------------------------------------------------------------
;
;   ok  ( -- ; a -- a )
;   using absolute address !
;   tricky absolute 
HEADER "BRANCH", "BRANCH", F_LEAP + F_CORE, LEAF
    ; link reference
    ; save link
    sty y_save
    ; load 
    ldy #0
    lda (lnk), y
    sta a_save
    ldy #1
    lda (lnk), y
    ; save
    sta lnk + 1
    lda a_save
    sta lnk + 0
    ; load index
    ldy y_save
    ; continue
    jmp link

;---------------------------------------------------------------------
;
;   ok  ( w -- ; -- )
;
HEADER "0BRANCH", "ZBRANCH", F_LEAP + F_CORE, LEAF
    lda #0
    cmp spz + 0, x
    bne NOBRANCH
    cmp spz + 1, x
    bne NOBRANCH
    inx
    inx
    jmp BRANCH

;---------------------------------------------------------------------
;
;   ok  ( -- ;  -- )
;
HEADER "NOBRANCH", "NOBRANCH", F_LEAP + F_CORE, LEAF

    clc
    inc lnk + 0
    inc lnk + 0
    bne @end
    inc lnk + 1
@end:
    jmp DROP

;---------------------------------------------------------------------
;
;   ok  ( w -- ; -- w)
;
HEADER "EXE", "EXE", F_LEAP + F_CORE, LEAF
    ; push the link reference
    dey
    lda lnk + 0
    sta rpz, y
    dey
    lda lnk + 1
    sta rpz, y
    jmp TOR

;---------------------------------------------------------------------
;
;   ok  (  -- w ; a -- a+CELL )
;
HEADER "LIT", "LIT", F_LEAP + F_CORE, LEAF
    ; get link reference
    ; save link
    sty y_save
    ldy #0
    lda (lnk), y
    dex
    sta spz, x
    ldy #1
    lda (lnk), y
    dex
    sta spz, x
    ; load index
    ldy y_save
    jmp NOBRANCH

;---------------------------------------------------------------------
;
;   ok  ( a -- w )
;
HEADER "@", "AT", F_LEAP + F_CORE, LEAF
    ; load address to page zero
    lda spz + 0, x
    sta wrk + 0
    lda spz + 1, x
    sta wrk + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda (wrk), y
    sta spz + 0, x
    ; copy msb
    ldy #1
    lda (wrk), y
    sta spz + 1, x
    ; load index
    ldy y_save
    ; continue
    jmp link

;---------------------------------------------------------------------
;
;   ok  ( w1 w2 -- )
;   
HEADER "!", "TO", F_LEAP + F_CORE, LEAF
    ; load address to page zero
    lda spz + 0, x
    sta wrk + 0
    lda spz + 1, x
    sta wrk + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda spz + 2, x
    sta (wrk), y
    ; copy msb
    iny
    lda spz + 3, x
    sta (wrk), y
    ; load index
    ldy y_save
    ; 2drop
    inx 
    inx
    jmp DROP 
    
;---------------------------------------------------------------------
;
;   ok  ( a -- c )
;
HEADER "C@", "CAT", F_LEAP + F_CORE, LEAF
    ; load address to page zero
    lda spz + 0, x
    sta wrk + 0
    lda spz + 1, x
    sta wrk + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda (wrk), y
    sta spz + 0, x
    ; clear msb
    lda #0
    sta spz + 1, x
    ; load index
    ldy y_save
    ; continue
    jmp link

;---------------------------------------------------------------------
;
;   ok  ( c a -- )
;
HEADER "C!", "CTO", F_LEAP + F_CORE, LEAF
    ; load address to page 0
    lda spz + 0, x
    sta wrk + 0
    lda spz + 1, x
    sta wrk + 1
    ; save index
    sty y_save
    ; copy only lsb
    ldy #0
    lda spz + 2, x
    sta (wrk), y
    ; load index
    ldy y_save
    ; continue
    inx
    inx
    jmp DROP
    
;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "1+", "PLUS1", F_LEAP + F_CORE, LEAF
    lda #1
adds:
    clc
    adc spz + 0, x
    sta spz + 0, x
    lda #0
    adc spz + 1, x
    sta spz + 1, x
    ; continue
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "2+", "PLUS2", F_LEAP + F_CORE, LEAF
    lda #2
    jmp adds

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "3+", "PLUS3", F_LEAP + F_CORE, LEAF
    lda #3
    jmp adds

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "4+", "PLUS4", F_LEAP + F_CORE, LEAF
    lda #4
    jmp adds

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + ( 0 - 1 )
;
HEADER "1-", "MINUS1", F_LEAP + F_CORE, LEAF
    lda #$FF
    jmp adds

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + ( 0 - 2 )
;
HEADER "2-", "MINUS2", F_LEAP + F_CORE, LEAF
    lda #$FE
    jmp adds

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + ( 0 - 2 )
;
HEADER "3-", "MINUS3", F_LEAP + F_CORE, LEAF
    lda #$FD
    jmp adds

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + ( 0 - 4 )
; 
HEADER "4-", "MINUS4", F_LEAP + F_CORE, LEAF
    lda #$FC
    jmp adds

;---------------------------------------------------------------------
; 
; ok (  -- 1 )
;
HEADER "CHAR", "CHAR", F_LEAP + F_CORE, LEAF
    jmp ONE

;---------------------------------------------------------------------
; 
; ok ( w -- w )
;
HEADER "CHARS", "CHARS", F_LEAP + F_CORE, LEAF
    jmp ONE

;---------------------------------------------------------------------
; 
; ok ( w -- w+char )
;
HEADER "CHAR+", "CHARPLUS", F_LEAP + F_CORE, LEAF
    jmp PLUS1

;---------------------------------------------------------------------
; 
; ok ( w -- w-char )
;
HEADER "CHAR-", "CHARMINUS", F_LEAP + F_CORE, LEAF
    jmp MINUS1

;---------------------------------------------------------------------
; 
; ok (  -- cell )
;
HEADER "CELL", "CELL", F_LEAP + F_CORE, LEAF
    jmp TWO

;---------------------------------------------------------------------
; 
; ok ( w -- w*cell )
; tricky cell is 2 then shift left one bit
HEADER "CELLS", "CELLS", F_LEAP + F_CORE, LEAF
    jmp LSHL

;---------------------------------------------------------------------
; 
; ok ( w -- w+cell )
;
HEADER "CELL+", "CELLPLUS", F_LEAP + F_CORE, LEAF
    jmp PLUS2

;---------------------------------------------------------------------
; 
; ok ( w -- w-cell )
;
HEADER "CELL-", "CELLMINUS", F_LEAP + F_CORE, LEAF
    jmp MINUS2

;---------------------------------------------------------------------
; 
; ok ( w1 w2 -- w2 w1 )
;
HEADER "SWAP", "SWAP", F_LEAP + F_CORE, LEAF
    ; swap lsb
    lda spz + 0, x
    sta a_save
    lda spz + 2, x
    sta spz + 0, x
    lda a_save
    sta spz + 2, x
    ; swap msb
    lda spz + 1, x
    sta a_save 
    lda spz + 3, x
    sta spz + 1, x
    lda a_save
    sta spz + 3, x
    ; continue
    jmp link

;---------------------------------------------------------------------
; 
; ok ( w1 w2 w3 -- w2 w3 w1 )
;
HEADER "ROT", "ROT", F_LEAP + F_CORE, LEAF
    ; swap lsb
    lda spz + 4, x
    sta a_save
    lda spz + 2, x
    sta spz + 4, x
    lda spz + 0, x
    sta spz + 2, x
    lda a_save
    sta spz + 0, x
    ; swap msb
    lda spz + 5, x
    sta a_save
    lda spz + 3, x
    sta spz + 5, x
    lda spz + 1, x
    sta spz + 3, x
    lda a_save
    sta spz + 1, x
    ; continue
    jmp link

;------------------------------------------------------------------------------
;
;   adapted from  http://forum.6502.org/viewtopic.php?f=9&t=689
;   ok ( multiplier multiplicant -- result_lsb result_msb )
;
HEADER "U*", "USTAR", F_LEAP + F_CORE, LEAF
    ; save index
    sty y_save

    ; copy multiplier
    lda spz + 2, x
    sta wrk
    lda spz + 3, x
    sta wrk + 1

    ; clear multiplier
    lda #0
    sta spz + 2, x
    sta spz + 3, x

    ; counter for 16 bits
    ldy #$10        

@loop:
    ; multiply by 2
    asl spz + 2, x
    rol spz + 3, x
    rol spz + 0, x
    rol spz + 1, x
    bcc @end

    ; add multiplier
    clc
    lda wrk
    adc spz + 2, x
    sta spz + 2, x
    lda wrk + 1
    adc spz + 3, x
    sta spz + 3, x
    bcc @end

    ; increase product
    ; lda #0, adc, sta
    inc spz + 0
    bne @end
    inc spz + 1

@end:
    dey
    bne @loop

    ; load index
    ldy y_save
    
    ; continue
    jmp link

;------------------------------------------------------------------------------
; also
;
HEADER "UM*", "UMSTAR", F_LEAP + F_CORE, LEAF
    jmp USTAR

;------------------------------------------------------------------------------
; 
; adapted from http://6502.org/source/integers/ummodfix/ummodfix.htm
; 
;   ok ( dividend divisor -- remainder quotient )
;
HEADER "U/", "USLASH", F_LEAP + F_CORE, LEAF
    ; save index
    sty y_save

    ; verify
    sec
    lda  spz + 2, x    ; Subtract hi cell of dividend by
    sbc  spz + 0, x    ; divisor to see if there's an overflow condition.
    lda  spz + 3, x
    sbc  spz + 1, x
    bcs  @oflow        ; Branch if /0 or overflow.

    ; counter
    ldy #11H         ; Loop 17x.

@loop:  
    rol  spz + 4, x    ; Rotate dividend lo cell left one bit.
    rol  spz + 5, x
    
    dey               ; Decrement loop counter.
    beq  @end         ; If we're done, then branch to end.

    rol  spz + 2, x    ; Otherwise rotate dividend hi cell left one bit.
    rol  spz + 3, x
    
    lda  #0           ; save carry
    sta  wrk + 0
    rol  wrk + 0      ; Rotate the bit carried out of above into N+1.

    ; Subtract dividend cell minus divisor.
    sec
    lda  spz + 2, x    
    sbc  spz + 0, x
    sta  wrk + 0      ; Put result temporarily in N+2 (lo byte)
    
    lda  spz + 3, x     
    sbc  spz + 1, x
    sta  wrk + 1      ; Put result temporarily in N+3 (hi byte)

    ; verify carry
    lda  wrk + 0
    sbc  #0
    bcc  @loop

    ; update dividend
    lda  wrk + 0      ; If that didn't cause a borrow,
    sta  spz + 2, x    ; make the result from above to
    lda  wrk + 1
    sta  spz + 3, x    ; be the new dividend hi cell
    bcs  @loop        ; and then brach up. (NMOS 6502 can use BCS here.)

@oflow:
    lda  #$FF         ; If overflow or /0 condition found,
    sta  spz + 2, x    ; just put FFFF in both the remainder
    sta  spz + 3, x
    sta  spz + 4, x    ; and the quotient.
    sta  spz + 5, x

@end:  
    ; load index
    ldy y_save

    ; drop and continue
    inx           ; When you're done, show one less cell on data stack,
    inx           ; (INX INX is exactly what the Forth word DROP does) 
    jmp  SWAP     ; and swap the two top cells to put quotient on top.

;------------------------------------------------------------------------------
; 
;   also
;
HEADER "UM/MOD", "UMMOD", F_LEAP + F_CORE, LEAF
    jmp USLASH

<<<<<<< HEAD
;;------------------------------------------------------------------------------
HEADER "LOG", "LOG", F_LEAP + F_CORE, LEAF 
; http://forum.6502.org/viewtopic.php?t=1249
;LOG_INPUT:  DFS  1
;
;
;8BIT_LOG: STA  LOG_INPUT   ; Start with input in A, and get the base-2 log, scaled by 32.
;          LDA  #11100000B  ; Init the integer part of the output.  Each 0 bit at the
;                           ; left end of the input will decrement it by 1(00000).  (Taking
;loop:     ASL  LOG_INPUT   ; the log of 0 is not allowed, so this won't reach -1.)
;          BCS  exloop      ; If carry is set, we found it, so branch.  Otherwise,
;          SBC  #011111B    ; decrement what will become the integer part of the answer.
;          BRA  loop        ; Repeat the loop until we've found the first 1 bit.
;                           ; (It's 011111B above instead of 100000B because C is clear.)
;exloop:   LSR  LOG_INPUT   ; What's left of the input after finding and stripping off
;          LSR  LOG_INPUT   ; the first 1 bit will be the fractional part of the answer.
;          LSR  LOG_INPUT   ; but its high bit needs to be in bit 4's position, not 7's,
;                           ; so shift it over three bit places.
;          ORA  LOG_INPUT   ; Output is in A.
;          RTS
	jmp link_
=======
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.if 0
;------------------------------------------------------
; A FORTH UM/MOD for any 6502 by Michael T. Barry.
                    ;
; ( ud u1 -- u2 u3 )
; ud is the 32-bit dividend.
; u1 is the 16-bit divisor.
; u2 is the 16-bit remainder.
; u3 is the 16-bit quotient.
; All values are unsigned.
                    ;
; Invalid results for quotient overflow or /0
                    ;
; 0,x and 1,x are TOS  ( divisor -- quotient )
; 2,x and 3,x are NOS  ( dividend:H -- remainder )
; 4,x and 5,x are 3OS  ( dividend:L --  )
                    ;
umslashmod:         ;
    ldy #16         ; loop counter
umsm2:              ;
    asl 4,x         ; dividend:L is gradually replaced
    rol 5,x         ;   with the quotient
    rol 2,x         ; dividend:H is gradually replaced
    rol 3,x         ;   with the remainder
    bcs umsm3       ;
    lda 2,x         ;
    cmp 0,x         ; compare remainder to divisor
    lda 3,x         ;
    sbc 1,x         ;
    bcc umsm4       ;
umsm3:              ;
    lda 2,x         ;
    sbc 0,x         ; if (remainder >= divisor) then
    sta 2,x         ;   update partial remainder
    lda 3,x         ;
    sbc 1,x         ;
    sta 3,x         ;
    inc 4,x         ;   and set low bit in quotient
umsm4:              ;
    dey             ;
    bne umsm2       ; Loop until done
    inx             ; Exit sequence:
    inx             ;   DROP the divisor
    jmp SWAP        ;   SWAP quotient and remainder
                    ; (SWAP's machine code, not its CFA)
;------------------- 44 bytes, not counting HEADER
;-----------------------------------------------------;
; var[x] /= var[x+2] (unsigned), {%} = remainder
; var[x+2] of 0 produces {%} = var[x], var[x] = 65535
; 39 bytes                                            ;
div:
    phy             ;
    ldy  #16        ; loop counter
    lda  #0         ;
    sta  remn+1     ; {%} = 0
div2:
    asl  0,x        ; dividend gradually becomes
    rol  1,x        ;   the quotient
    rol             ; {%} gradually becomes the
    rol  remn+1     ;   remainder
    cmp  2,x        ;
    pha             ;
    lda  remn+1     ;
    sbc  3,x        ; partial remainder >= divisor?
    bcc  div3       ;
    sta  remn+1     ;
    pla             ;   yes: update the partial
    sbc  2,x        ;     remainder and set the low
    inc  0,x        ;     bit of partial quotient
    .db  $c9        ;     "cmp #" naked op-code
div3:
    pla             ;
    dey             ;
    bne  div2       ; loop 16 times
    sta  remn       ;
    ply             ;
    rts             ;
;~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
.endif

>>>>>>> ec6a7c8703111ba397ac96f6df1a0c32157bff51
;------------------------------------------------------------------------------
; ok ( w -- )
; does a real jump !!!
; wise end with 'jmp link'
;
HEADER "JUMP", "JUMP", F_LEAP + F_CORE, LEAF 
    lda spz + 0, x
    sta wrk + 0
    lda spz + 1, x
    sta wrk + 1
    inx
    inx
    jmp (wrk)

;------------------------------------------------------------------------------
; ok ( w -- w )
; 6502 is byte aligned, then just continue
; must be cell aligned
;
HEADER "ALIGNED", "ALIGNED", F_LEAP + F_CORE, LEAF
    lda spz + 0, x
    adc #1
    sta spz + 0, x
    bcc algn
    lda spz + 1, x
    adc #1 
    sta spz + 1, x
algn:    
    lda spz + 0, x
    and #$FE
    sta spz + 0, x
    jmp link

;------------------------------------------------------------------------------
; ok ( w -- w )
;
HEADER "><", "NIBBLE", F_LEAP + F_CORE, LEAF
    lda spz + 0, x
    sta a_save 
    lda spz + 1, x
    sta spz + 0, x
    lda a_save 
    sta spz + 1, x
    jmp link

;------------------------------------------------------------------------------
; ok ( w a -- )
;
HEADER "+!", "PLUSTO", F_LEAP + F_CORE, LEAF
    ; load address to page 0
    lda spz + 0, x
    sta wrk + 0, x
    lda spz + 1, x
    sta wrk + 1, x
    ; save index
    sty y_save
    ; process
    clc
    ; sum lsb
    ldy #0
    lda (wrk), y
    adc spz + 2, x
    sta (wrk), y
    ; sum msb
    ldy #1
    lda (wrk), y
    adc spz + 3, x
    sta (wrk), y
    ; load index
    ldy y_save
    ; continue
    inx
    inx
    jmp DROP

;------------------------------------------------------------------------------
; ok ( w a -- w )
;
HEADER "ABS", "ABS", F_LEAP + F_CORE, LEAF
    lda spz + 1, x
    bpl @pos
    jmp INEG
@pos:
    jmp link

;------------------------------------------------------------------------------
; ok ( w a -- w )
;
HEADER "DP", "DP", F_LEAP + F_CORE, LEAF
    dex
    dex
    lda #<list
    lda spz + 0, x
    lda #>list
    lda spz + 1, x
    jmp link

;======================================================================

.include "double.s"

;======================================================================
.END
