
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
;   need page zero for indirect address
;
.segment "ZEROPAGE"

reserved:   .res 240, $00

;---------------------------------------------------------------------
; pseudo registers, page zero
tos = $F0
nos = tos + 2
wrk = tos + 4
cnt = tos + 6

; copycat
a_save = tos + 8
s_save = tos + 9
x_save = tos + 10
y_save = tos + 11
p_save = tos + 12
h_save = tos + 13

;---------------------------------------------------------------------
;   system
;   irq mask stuff
irqnot = tos + 14  ; pending
irqcnt = tos + 15  ; nested
irqvec = tos + 16  ; resolver

;---------------------------------------------------------------------
; parameter stack, $0200
ps = $0200
pz = ps + $FF

;---------------------------------------------------------------------
; return stack, $0300
rs = $0300
rz = rs + $FF

;---------------------------------------------------------------------
; terminal input buffer, $0400
t0 = $0400
tz = t0 + TIB_SIZE

; pad buffer fix ?
; d0 = tz + 2
; dz = d0 + PAD_SIZE

;---------------------------------------------------------------------
; forth boot/reset
void = tz + 2   ; easy zero 
turn = tz + 4   ; routine pos-boot
rest = tz + 6   ; routine pre-reset
warn = tz + 8   ; error/warning level

; forth interpreter 
radx = tz + 10   ; base, radix for numbers
stat = tz + 12   ; state, interpreter state
last = tz + 14   ; latest, link to dictionary latest word
list = tz + 16   ; dp, pointer to dicionary next free cell

; status
csp = tz + 20  ; keep stack
hnd = tz + 22  ; handler for throw/catch
hld = tz + 24  ; holder for <# #>
tmp = tz + 26  ; scratch 

; devices
dsk = tz + 30   ; disk number
blk = tz + 32   ; block number (track)
sct = tz + 34   ; sector number
sns = tz + 36   ; sense number
scr = tz + 38   ; screen number

;=====================================================================

.include "bios.s"

;=====================================================================
;
.segment "CODE"

;======================================================================
;
;   words to do...
;
COLD:
WARM:
TIME:
WATCH:

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
;   inner address interpreter, using MITC
;   classic ITC, nos == IP, wrk == WR
;
;   in classic ITC, the code always jump and 
;   when DOCOL does a push to return stack.
;
;   in minimal ITC, the code only jumps when first reference is 0x0000
;   that marks all primitives else does a push to return stack
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
;   all BRANCH are absolute references. No offsets.

;   rs top of return stack, y index
;   ps top of parameter stack, x index
;   tos, nos, wrk, cnt pseudo registers at page zero
;   a_save, x_save, y_save, keep values
;
;   |top ...                | stack
;   | 1st   2nd   3nd   4th | cells
;   |[0,1] [2,3] [4,5] [6,7]| offsets at stack, [LSB,MSB]
;   |low                high| address
;
;   att: never use negative offsets as -1, -2, etc 
;
;   use of jumps for reduce code size;
;   minimal use of JSR/RTS, PHA, PLA;
;   minimal use of page zero;
;   acumulator used as is.
;
;   ps, x   parameter stack
;   rs, y   return stack
;
;   ATT: KEEP THE WORDS AT BRANCH OFFSETS (-127 to +127) or COLAPSE
;
HEADER "ENDS", "ENDS", F_LEAP, LEAF
unnest:     ; aka semis
    ; pull from return stack
    lda rs + 0, y
    sta nos + 0
    lda rs + 1, y
    sta nos + 1
    iny
    iny
    ; jmp next

next:
    ; as is, classic ITC from fig-forth 6502
    sty y_save
    ldy #0
    lda (nos), y
    sta wrk + 0
    iny
    lda (nos), y
    sta wrk + 1
    ldy y_save

    ; pointer to next reference
    clc
    lda nos + 0
    adc #CELL_SIZE
    sta nos + 0
    bne @end
    inc nos + 1
@end:

leaf:
    ; in MICT, all leafs start with NULL
    ; in 6502, none code at page zero
    ; just compare high byte
    lda #0
    cmp wrk + 1
    bne nest
    ; non forth word at page zero
    jmp (nos)

nest:       ; aka docol
    ; push into return stack
    dey
    dey
    lda nos + 1
    sta rs + 1, y
    lda nos + 0
    sta rs + 0, y

link:
    ; next reference
    lda wrk + 0
    sta nos + 0
    lda wrk + 1
    sta nos + 1
    jmp next

;---------------------------------------------------------------------

; 
; ok ( -- )
;
HEADER "NOP", "NOOP", F_LEAP, LEAF
    jmp unnest

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
fflag:
    dex
    dex
    sta ps + 0, x
    sta ps + 1, x
    ; continue
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w -- false | true ) \ test w = 0
;
HEADER "0=", "ZEQU", F_LEAP + F_CORE, LEAF
    lda ps + 0, x
    ora ps + 1, x
    bne false1
    beq true1

;---------------------------------------------------------------------
; 
; ok ( w -- false | true ) \ test w < 0
;
HEADER "0<", "ZLESS", F_LEAP + F_CORE, LEAF
    lda ps + 1, x
    bmi true1
    bpl false1

;---------------------------------------------------------------------
; 
false2:
    inx
    inx

;---------------------------------------------------------------------
; 
false1:
    inx
    inx
    jmp FFALSE

;---------------------------------------------------------------------
; 
true2:
    inx
    inx

;---------------------------------------------------------------------
; 
true1:
    inx
    inx
    jmp FTRUE

;---------------------------------------------------------------------
;
; ok ( w1 w2  -- false | true ) \ test w1 > w2
;
HEADER "=", "EQU", F_LEAP + F_CORE, LEAF
    lda ps + 1, x
    cmp ps + 3, x
    bne false2
    lda ps + 0, x
    cmp ps + 2, x
    bne false2
    beq true2 

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- false | true ) \ test w1 < w2
; look no overflow, SO pin free 
HEADER "<", "LESS", F_LEAP + F_CORE, LEAF
    lda ps + 1, x
    eor #$80
    sta a_save
    lda ps + 3, x
    eor #$80
    cmp a_save
    bcc true2
    bne false2
    lda ps + 0, x
    cmp ps + 2, x
    bcc true2
    bcs false2

;---------------------------------------------------------------------
;
;   ok  ( w1 w2 -- flag ) \ w1 < w2 
;
HEADER "U<", "UMLESS", F_LEAP + F_CORE, LEAF
    lda ps + 3, x
    cmp ps + 1, x
    bcc true2
    bne false2
    lda ps + 2, x
    cmp ps + 0, x
    bcc true2
    bcs false2

;---------------------------------------------------------------------
;
;   ok  ( w1 w2 -- w3 carry )
;
HEADER "U+", "UMPLUS", F_LEAP + F_CORE, LEAF
    clc
    lda ps + 2, x
    adc ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    adc ps + 1, x
    sta ps + 3, x
    ; save carry flag
    lda #0
    sta ps + 1, x
    adc #0
    sta ps + 0, x
    ; continue
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w1 -- w2 ) \  rotate right
;
HEADER "SHR", "LSHR", F_LEAP + F_CORE, LEAF
    lsr ps + 1, x
    ror ps + 0, x
    ; continue
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w1 -- w2 ) \  rotate left
;
HEADER "SHL", "LSHL", F_LEAP + F_CORE, LEAF
    asl ps + 0, x
    rol ps + 1, x
    ; continue
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w1 -- w2 ) \  rotate right
; by book
HEADER "2/", "ASHR", F_LEAP + F_CORE, LEAF
    ; copy sign bit
    lda ps + 1, x
    and #$80
    sta a_save
    ; shift
    lsr ps + 1, x
    ror ps + 0, x
    ; mask sign bit
    lda ps + 1, x
    ora a_save
    sta ps + 1, x
    ; continue
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w1 -- w2 ) \  rotate right
; by book
HEADER "2*", "ASHL", F_LEAP + F_CORE, LEAF
    ; copy sign bit
    lda ps + 1, x
    and #$80
    sta a_save
    ; shift
    asl ps + 0, x
    rol ps + 1, x
    ; mask sign bit
    lda ps + 1, x
    ora a_save
    sta ps + 1, x
    ; continue
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w1 -- w2 ) \  NOT w1 
;
HEADER "INVERT", "IINV", F_LEAP + F_CORE, LEAF
    lda #$FF
    eor ps + 0, x
    sta ps + 0, x
    eor ps + 1, x
    sta ps + 1, x
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w1  -- w3 ) \  0x00 - w1
;
HEADER "NEGATE", "INEG", F_LEAP + F_CORE, LEAF
    sec
    lda #0
    sbc ps + 1, x
    sta ps + 1, x
    lda #0
    sbc ps + 0, x
    sta ps + 0, x
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- w3 ) \  w1 + w2
;
HEADER "+", "PLUS", F_LEAP + F_CORE, LEAF
    clc
    lda ps + 2, x
    adc ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    adc ps + 1, x
    sta ps + 3, x
    jmp DROP

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- w3 ) \  w1 - w2
;
HEADER "-", "MINUS", F_LEAP + F_CORE, LEAF
    sec
    lda ps + 2, x
    sbc ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    sbc ps + 1, x
    sta ps + 3, x
    jmp DROP

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- w3 ) \  w1 AND w2
;
HEADER "AND", "IAND", F_LEAP + F_CORE, LEAF
    lda ps + 2, x
    and ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    and ps + 1, x
    sta ps + 3, x
    jmp DROP

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- w3 ) \  w1 OR w2
;
HEADER "OR", "IOR", F_LEAP + F_CORE, LEAF
    lda ps + 2, x
    ora ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    ora ps + 1, x
    sta ps + 3, x
    jmp DROP

;---------------------------------------------------------------------
; 
; ok ( w1 w2  -- w3 ) \  w1 XOR w2
;
HEADER "XOR", "IXOR", F_LEAP + F_CORE, LEAF
    lda ps + 2, x
    eor ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    eor ps + 1, x
    sta ps + 3, x
    jmp DROP

;---------------------------------------------------------------------
; 
; ok ( w -- ) \  
;
HEADER "DROP", "DROP", F_LEAP + F_CORE, LEAF
    inx
    inx
    ; continue
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w -- w w ) \  
;
HEADER "?DUP", "QDUP", F_LEAP + F_CORE, LEAF
    lda ps + 0, x
    ora ps + 1, x
    bne @nodup
    jmp DUP
@nodup:
    jmp unnest

;---------------------------------------------------------------------
; ok ( w -- w w ) \  
;
HEADER "DUP", "DUP", F_LEAP + F_CORE, LEAF
    dex
    dex
    lda ps + 2, x
    sta ps + 0, x
    lda ps + 3, x
    sta ps + 1, x
    ; continue
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w1 w2 -- w1 w2 w1 ) \  
;
HEADER "OVER", "OVER", F_LEAP + F_CORE, LEAF
    dex
    dex
    lda ps + 4, x
    sta ps + 0, x
    lda ps + 5, x
    sta ps + 1, x
    ; continue
    jmp unnest

;---------------------------------------------------------------------
;
;   ok  ( -- wrk )
;
HEADER "SP!", "PSTO", F_LEAP + F_CORE, LEAF
    lda ps + 0, x
    tax
    jmp DROP 

;---------------------------------------------------------------------
;
;   ok  ( -- wrk )
;
HEADER "RP!", "RSTO", F_LEAP + F_CORE, LEAF
    lda ps + 0, x
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
    ; preserve next return
    lda rs + 2, y
    sta rs + 0, y
    lda rs + 3, y
    sta rs + 1, y
    ; move values
    lda ps + 0, x
    sta rs + 2, y
    lda ps + 1, x
    sta rs + 3, y
    inx
    inx
    ; continue
    jmp unnest

;---------------------------------------------------------------------
;
;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R>", "RTO", F_LEAP + F_CORE, LEAF
    dex
    dex
    ; move values
    lda rs + 2, y
    sta ps + 0, x
    lda rs + 3, y
    sta ps + 1, x
    ; preserve next return
    lda rs + 0, x
    sta rs + 2, y
    lda rs + 1, x
    sta rs + 3, y
    iny
    iny
    ; continue
    jmp unnest

;---------------------------------------------------------------------
;
;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R@", "RAT", F_LEAP + F_CORE, LEAF
    dex
    dex
    ; move values
    lda rs + 2, y
    sta ps + 0, x
    lda rs + 3, y
    sta ps + 1, x
    ; continue
    jmp unnest

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
    sta ps + 0, x
    ; clear msb
    lda #0
    sta ps + 1, x
    ; continue
    jmp unnest

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
    ; get reference
    lda rs + 0, y
    sta nos
    lda rs + 1, y
    sta nos + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda (nos), y
    sta rs + 0, y
    ; copy msb
    iny
    lda (nos), y
    sta rs + 1, y
    ; load index
    ldy y_save
    ; continue
    jmp unnest

;---------------------------------------------------------------------
;
;   ok  ( w -- ; -- )
;
HEADER "0BRANCH", "ZBRANCH", F_LEAP + F_CORE, LEAF
    lda #0
    cmp ps + 0, x
    bne NOBRANCH
    cmp ps + 1, x
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
    lda rs + 0, y
    adc CELL_SIZE
    sta rs + 0, y
    bcc @nobranch
    lda rs + 1, y
    adc #1
    sta rs + 1, y
@nobranch:
    jmp DROP

;---------------------------------------------------------------------
;
;   ok  ( w -- ; -- w)
;
HEADER "EXE", "EXE", F_LEAP + F_CORE, LEAF
    jmp TOR

;---------------------------------------------------------------------
;
;   ok  (  -- w ; a -- a+CELL )
;
HEADER "LIT", "LIT", F_LEAP + F_CORE, LEAF
    ; get reference
    dex
    dex
    ; get reference
    lda rs + 0, y
    sta nos
    lda rs + 1, y
    sta nos + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda (nos), y
    sta ps + 0, x 
    ; copy msb
    iny
    lda (nos), y
    sta ps + 1, x
    ; load index
    ldy y_save
    ; continue
    dex
    dex
    jmp NOBRANCH

;---------------------------------------------------------------------
;
;   ok  ( a -- w )
;
HEADER "@", "AT", F_LEAP + F_CORE, LEAF
    ; load address to page zero
    lda ps + 0, x
    sta nos + 0
    lda ps + 1, x
    sta nos + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda (nos), y
    sta ps + 0, x
    ; copy msb
    iny
    lda (nos), y
    sta ps + 1, x
    ; load index
    ldy y_save
    ; continue
    jmp unnest

;---------------------------------------------------------------------
;
;   ok  ( w1 w2 -- )
;   
HEADER "!", "TO", F_LEAP + F_CORE, LEAF
    ; load address to page zero
    lda ps + 0, x
    sta nos + 0
    lda ps + 1, x
    sta nos + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda ps + 2, x
    sta (nos), y
    ; copy msb
    iny
    lda ps + 3, x
    sta (nos), y
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
    lda ps + 0, x
    sta nos + 0
    lda ps + 1, x
    sta nos + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda (nos), y
    sta ps + 0, x
    ; clear msb
    lda #0
    sta ps + 1, x
    ; load index
    ldy y_save
    ; continue
    jmp unnest

;---------------------------------------------------------------------
;
;   ok  ( c a -- )
;
HEADER "C!", "CTO", F_LEAP + F_CORE, LEAF
    ; load address to page 0
    lda ps + 0, x
    sta nos + 0
    lda ps + 1, x
    sta nos + 1
    ; save index
    sty y_save
    ; copy only lsb
    ldy #0
    lda ps + 2, x
    sta (nos), y
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
adcs:
    clc
    adc ps + 0, x
    sta ps + 0, x
    lda #0
    adc ps + 1, x
    sta ps + 1, x
    ; continue
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "2+", "PLUS2", F_LEAP + F_CORE, LEAF
    lda #2
    jmp adcs

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "4+", "PLUS4", F_LEAP + F_CORE, LEAF
    lda #4
    jmp adcs

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + ( 0 - 1 )
;
HEADER "1-", "MINUS1", F_LEAP + F_CORE, LEAF
    lda #$FF
    jmp adcs

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + ( 0 - 2 )
;
HEADER "2-", "MINUS2", F_LEAP + F_CORE, LEAF
    lda #$FE
    jmp adcs

;---------------------------------------------------------------------
; 
; ok ( w1  -- w2 ) \  w1 + ( 0 - 4 )
; 
HEADER "4-", "MINUS4", F_LEAP + F_CORE, LEAF
    lda #$FC
    jmp adcs

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
;
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
    lda ps + 0, x
    sta a_save
    lda ps + 2, x
    sta ps + 0, x
    lda a_save
    sta ps + 2, x
    ; swap msb
    lda ps + 1, x
    sta a_save 
    lda ps + 3, x
    sta ps + 1, x
    lda a_save
    sta ps + 3, x
    ; continue
    jmp unnest

;---------------------------------------------------------------------
; 
; ok ( w1 w2 w3 -- w2 w3 w1 )
;
HEADER "ROT", "ROT", F_LEAP + F_CORE, LEAF
    ; swap lsb
    lda ps + 4, x
    sta a_save
    lda ps + 2, x
    sta ps + 4, x
    lda ps + 0, x
    sta ps + 2, x
    lda a_save
    sta ps + 0, x
    ; swap msb
    lda ps + 5, x
    sta a_save
    lda ps + 3, x
    sta ps + 5, x
    lda ps + 1, x
    sta ps + 3, x
    lda a_save
    sta ps + 1, x
    ; continue
    jmp unnest

;------------------------------------------------------------------------------
;
;   adapted from  http://forum.6502.org/viewtopic.php?f=9&t=689
;   ok ( multiplier multiplicant -- result_lsb result_msb )
;
HEADER "U*", "USTAR", F_LEAP + F_CORE, LEAF
    ; save index
    sty y_save

    ; copy multiplier
    lda ps + 2, x
    sta nos
    lda ps + 3, x
    sta nos + 1

    ; clear multiplier
    lda #0
    sta ps + 2, x
    sta ps + 3, x

    ; counter for 16 bits
    ldy #$10        

@loop:
    ; multiply by 2
    asl ps + 2, x
    rol ps + 3, x
    rol ps + 0, x
    rol ps + 1, x
    bcc @end

    ; add multiplier
    clc
    lda nos
    adc ps + 2, x
    sta ps + 2, x
    lda nos + 1
    adc ps + 3, x
    sta ps + 3, x
    bcc @end

    ; increase product
    ; lda #0, adc, sta
    inc ps + 0
    bne @end
    inc ps + 1

@end:
    dey
    bne @loop

    ; load index
    ldy y_save
    
    ; continue
    jmp unnest

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
    lda  ps + 2, x    ; Subtract hi cell of dividend by
    sbc  ps + 0, x    ; divisor to see if there's an overflow condition.
    lda  ps + 3, x
    sbc  ps + 1, x
    bcs  @oflow        ; Branch if /0 or overflow.

    ; counter
    ldy #11H         ; Loop 17x.

@loop:  
    rol  ps + 4, x    ; Rotate dividend lo cell left one bit.
    rol  ps + 5, x
    
    dey               ; Decrement loop counter.
    beq  @end         ; If we're done, then branch to end.

    rol  ps + 2, x    ; Otherwise rotate dividend hi cell left one bit.
    rol  ps + 3, x
    
    lda  #0           ; save carry
    sta  nos + 0
    rol  nos + 0      ; Rotate the bit carried out of above into N+1.

    ; Subtract dividend cell minus divisor.
    sec
    lda  ps + 2, x    
    sbc  ps + 0, x
    sta  wrk + 0      ; Put result temporarily in N+2 (lo byte)
    
    lda  ps + 3, x     
    sbc  ps + 1, x
    sta  wrk + 1      ; Put result temporarily in N+3 (hi byte)

    ; verify carry
    lda  nos + 0
    sbc  #0
    bcc  @loop

    ; update dividend
    lda  wrk + 0      ; If that didn't cause a borrow,
    sta  ps + 2, x    ; make the result from above to
    lda  wrk + 1
    sta  ps + 3, x    ; be the new dividend hi cell
    bcs  @loop        ; and then brach up. (NMOS 6502 can use BCS here.)

@oflow:
    lda  #$FF         ; If overflow or /0 condition found,
    sta  ps + 2, x    ; just put FFFF in both the remainder
    sta  ps + 3, x
    sta  ps + 4, x    ; and the quotient.
    sta  ps + 5, x

@end:  
    ; load index
    ldy y_save

    ; drop and continue
    inx           ; When you're done, show one less cell on data stack,
    inx           ; (INX INX is exactly what the Forth word DROP does) 
    jmp  SWAP     ; and swap the two top cells to put quotient on top.

;------------------------------------------------------------------------------
; also
;
HEADER "UM/MOD", "UMMOD", F_LEAP + F_CORE, LEAF
    jmp USLASH

;------------------------------------------------------------------------------
; ok ( w -- )
; does a real jump !!!
; wise end with 'jmp unnest'
;
HEADER "JUMP", "JUMP", F_LEAP + F_CORE, LEAF 
    lda ps + 0, y
    sta nos + 0
    lda ps + 1, y
    sta nos + 1
    iny
    iny
    jmp (nos)

;------------------------------------------------------------------------------
; ok ( w -- w )
; 6502 is byte aligned, then just continue
;
HEADER "ALIGNED", "ALIGNED", F_LEAP + F_CORE, LEAF
    jmp unnest

;------------------------------------------------------------------------------
; ok ( w -- w )
;
HEADER "><", "NIBBLE", F_LEAP + F_CORE, LEAF
    lda ps + 0, x
    sta nos + 0
    lda ps + 1, x
    sta ps + 0, x
    lda nos + 0
    sta ps + 1, x
    jmp unnest

;------------------------------------------------------------------------------
; ok ( w a -- w )
;
HEADER "+!", "PLUSTO", F_LEAP + F_CORE, LEAF
    ; load address to page 0
    lda ps + 0, x
    sta nos + 0, x
    lda ps + 1, x
    sta nos + 1, x
    ; save index
    sty y_save
    ; process
    clc
    ; sum lsb
    ldy #0
    lda (nos), y
    adc ps + 2, x
    sta (nos), y
    ; sum msb
    iny
    lda (nos), y
    adc ps + 3, x
    sta (nos), y
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
    lda ps + 1, x
    bpl @pos
    jmp INEG
@pos:
    jmp unnest

;------------------------------------------------------------------------------
; ok ( w a -- w )
;
HEADER "DP", "DP", F_LEAP + F_CORE, LEAF
    dex
    dex
    lda #<list
    lda ps + 0, x
    lda #>list
    lda ps + 1, x
    jmp unnest

;======================================================================

.include "double.s"


;======================================================================
.END
