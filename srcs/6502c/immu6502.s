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
;---------------------------------------------------------------------
;
;   04/01/2023   please read the Notes.md
;
;---------------------------------------------------------------------
;   enable some ca65  
;
; enable listing
.list on

; lines per page
.pagelength 66

; enable 6502 mode
.p02


;---------------------------------------------------------------------
; macros

.define VERSION "0.01.02"

.define EQU =

;.dword .time

;---------------------------------------------------------------------
; 
; borrow from C
NULL    = $0000

; logical flags, forth 83
FALSE   = 0
TRUE    = 255

; buffer sizes
TIB_SIZE    = 80
PAD_SIZE    = 72

; cell is 16 bits, 2 bytes
CELL_SIZE = 2

; maximum word size
WORD_SIZE = 15

; default base
BASE_DEFAULT = 16

;---------------------------------------------------------------------
; forth words flags
;
F_RESERVED = $80
F_IMMEDIATE = $40
F_COMPILE = $20
F_HIDDEN = $10

F_TOMASK = $F0
F_UNMASK = $0F

; not flags but usefull to remember at listings
F_LEAP = $00   ; for primitives
F_CORE = $00   ; for core words

;---------------------------------------------------------------------
;
; minimal error codes from forth 2012
;
NO_ERROR = 0
INVALID_MEMORY = 9
OUT_OF_RANGE = 11
INVALID_WORD = 13
TO_READ_ONLY = 20
NOT_A_NUMBER = 24

;---------------------------------------------------------------------
; ASCII constants
;
; Flow Control
; assumes that all line edit is done at remote!
; just a static line.
; works as a screen or block, just receives a line till a CR or CR LF
; uses BS, for edit last char
;
ESC_    =   27    ; ascii escape ^[
XON_    =   17    ; ascii DC1 ^Q
XOFF_   =   19    ; ascii DC3 ^S

CR_     =   13    ; ascci carriage return ^M
LF_     =   10    ; ascii line feed ^J
BS_     =    8    ; ascii backspace ^H

BL_     =   32    ; ascii space
QT_     =   34    ; ascii double quotes \"

;---------------------------------------------------------------------
; macros generic

_link_ .set NULL
_last_ .set NULL

.macro makelabel arg1, arg2
.ident(.concat(arg1, arg2)):
.endmacro

.macro HEADER name, label, flags

.ifblank flags
    .out " No flags "
.endif
.ifblank label
    .error " No label "
.endif
.ifblank name
    .error " No name "
.endif

makelabel "is_", label

;.ident(.concat("is_",.string(label))):

; cpu is byte unit
;    .align 2, $00  
    _last_ .set *
    .word _link_
    .byte .strlen(name) + flags + 0
    .byte name
; cpu is byte unit
;    .align 2, $20
    _link_ .set _last_

makelabel "", label

;.ident (.concat (label,":"))

.endmacro

.macro NOOP
    .word NULL
.endmacro

.enum
    HALT    = 0
    IDLE    = 1
    WAIT    = 2
    BUSY    = 3
.endenum

;---------------------------------------------------------------------
; need 8 bytes at page zero for indirect address
;
.segment "PZ"
.org NULL

reserved: .res 244

; copycat
x_save: .res 1
y_save: .res 1
a_save: .res 1
s_save: .res 1
p_save: .res 1
h_save: .res 1

; pseudo registers
cnt:
tos: .res 2     ; classic TOS

nos:
ptr: .res 2     ; classic IP

wrk: 
nxt: .res 2     ; classic W

;---------------------------------------------------------------------
.segment "DATA"
.org $0200
p0: .res $0100
r0: .res $0100
t0: .res TIB_SIZE

base:   .word $0010
state:  .word $0000
last:   .word NULL   ; link to dictionary latest word
dp:     .word NULL   ; pointer to dicionary next free cell
dsk:    .word NULL   ; disk number
blk:    .word NULL   ; block number
sct:    .word NULL   ; sector number
scr:    .word NULL   ; screen number
csp:    .word NULL
hnd:    .word NULL
hld:    .word NULL

;---------------------------------------------------------------------
;
.segment "VECTORS"

.addr      _nmi_int    ; NMI vector
.addr      _init       ; Reset vector
.addr      _irq_int    ; IRQ/BRK vector

;---------------------------------------------------------------------
;
.segment "STARTUP"

_init:
    ; disable interrupts
    sei

    ; no BCD math
    cld

    ; clear memory
    lda #0
    ldx #0
    :
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    ;sta $0400, x
    ;sta $0500, x
    ;sta $0600, x
    ;sta $0700, x
    inx
    bne :-

    ; offset stacks
    ldy #$FF
    ldx #$FF
    txs

    ; stack reference absolute
    ; high bytes
    lda $02
    sta p0 + 1
    lda $03
    sta r0 + 1
    ; low bytes
    lda $00
    sta p0
    sta r0

    ; enable interrupts
    cli
    
    ;
    jsr _main

;---------------------------------------------------------------------
;
.segment "CODE"

_nmi_int:
    ; return
    rti

_irq_int:
    ; save registers
    pha
    txa
    pha
    tya
    pha
    
    ; verify status
    tsx
    inx
    inx
    lda $100, x
    and #$10
    bne _break
    
    ;
    ; do something somewhere
    ;

    ; load registers
_irq:
    pla
    tay
    pla
    tax
    pla

    ; return 
    rti

_break:
    jmp _halt

    
;---------------------------------------------------------------------
irq:
    ; save register
    pha
    txa
    pha
    tya
    pha
    ; load register
    pla
    tay
    pla
    tax
    pla
    ; 
    rti

;---------------------------------------------------------------------
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

;---------------------------------------------------------------------
; inner address interpreter, using MITC
; classic  ptr == IP, nxt == WR
; also ptr = nos, nxt = wrk
;
HEADER "ENDS", "ends", F_LEAP 
    NOOP
unnest:
    ; pull from return stack
    lda r0 + 0, y
    sta ptr + 0
    lda r0 + 1, y
    sta ptr + 1
    iny
    iny
    ; jmp next

next:
    ; as is, classic ITC from fig-forth 6502
    sty y_save
    ldy #0
    lda (ptr), y
    sta nxt + 0
    iny
    lda (ptr), y
    sta nxt + 1
    ldy y_save
    ; pointer to next reference
    clc
    lda ptr + 0
    adc #2
    sta ptr + 0
    bne :+
    inc ptr + 1
    :

jump:
    ; in MICT, all leafs start with NULL
    lda #0
    cmp nxt + 1
    bne nest
    ; none forth word at page zero
    jmp (ptr)

nest:
    ; push into return stack
    dey
    dey
    lda ptr
    sta r0 + 0, y
    lda ptr + 1
    sta r0 + 1, y

    ; next reference
    lda nxt + 0
    sta ptr + 0
    lda nxt + 1
    sta ptr + 1
    jmp next
; 
; ok ( -- false )
;
HEADER "FALSE", "FFALSE", F_LEAP + F_CORE
    NOOP
    lda #0
    jmp fflag

; 
; ok ( -- true )
;
HEADER "TRUE", "FTRUE", F_LEAP + F_CORE
    NOOP
    lda #255
    jmp fflag

; 
; ok ( -- flag )
;
HEADER "(flag)", "fflag", F_LEAP + F_CORE
    NOOP
    sta p0 + 0, x
    sta p0 + 1, x
    jmp unnest

; 
; ok ( w -- false | true ) \ test w = 0
;
HEADER "0=", "zequ", F_LEAP + F_CORE
    NOOP
    lda #0
    cmp p0 + 0, x
    bne FFALSE
    cmp p0 + 1, x
    bne FFALSE
    beq FTRUE

; 
; ok ( w -- false | true ) \ test w < 0
;
HEADER "0<", "zless", F_LEAP + F_CORE
    NOOP
    lda #0
    cmp p0 + 0, x
    bcc FFALSE
    cmp p0 + 1, x
    bcc FFALSE
    beq FTRUE

; 
; ok ( w1 w2  -- false | true ) \ test w1 > w2
;
HEADER "<", "less", F_LEAP + F_CORE
    NOOP
    lda p0 + 2, x
    cmp p0 + 0, x
    bcs FFALSE
    lda p0 + 3, x
    cmp p0 + 1, x
    bcs FFALSE
    beq FTRUE

; 
; ok ( w1 -- w2 ) \  rotate left
;
HEADER "2*", "shl", F_LEAP + F_CORE
    NOOP
    clc
    rol p0 + 0, x
    rol p0 + 1, x
    jmp unnest

; 
; ok ( w1 -- w2 ) \  rotate right
;
HEADER "2/", "shr", F_LEAP + F_CORE
    NOOP
    clc
    ror p0 + 1, x
    ror p0 + 0, x
    jmp unnest

; 
; ok ( w1 w2  -- w3 ) \  w1 + w2
;
HEADER "+", "plus", F_LEAP + F_CORE
    NOOP
    clc
    lda p0 + 2, x
    adc p0 + 0, x
    sta p0 + 2, x
    lda p0 + 3, x
    adc p0 + 1, x
    sta p0 + 3, x
    jmp drop

; 
; ok ( w1 w2  -- w3 ) \  w1 - w2
;
HEADER "-", "minus", F_LEAP + F_CORE
    NOOP
    sec
    lda p0 + 2, x
    sbc p0 + 0, x
    sta p0 + 2, x
    lda p0 + 3, x
    sbc p0 + 1, x
    sta p0 + 3, x
    jmp drop

; 
; ok ( w1 w2  -- w3 ) \  w1 AND w2
;
HEADER "AND", "iand", F_LEAP + F_CORE
    NOOP
    lda p0 + 2, x
    and p0 + 0, x
    sta p0 + 2, x
    lda p0 + 3, x
    and p0 + 1, x
    sta p0 + 3, x
    jmp drop

; 
; ok ( w1 w2  -- w3 ) \  w1 OR w2
;
HEADER "OR", "ior", F_LEAP + F_CORE
    NOOP
    lda p0 + 2, x
    ora p0 + 0, x
    sta p0 + 2, x
    lda p0 + 3, x
    ora p0 + 1, x
    sta p0 + 3, x
    jmp drop

; 
; ok ( w1 w2  -- w3 ) \  w1 XOR w2
;
HEADER "XOR", "ixor", F_LEAP + F_CORE
    NOOP
    lda p0 + 2, x
    eor p0 + 0, x
    sta p0 + 2, x
    lda p0 + 3, x
    eor p0 + 1, x
    sta p0 + 3, x
    jmp drop

; 
; ok ( w -- ) \  
;
HEADER "DROP", "drop", F_LEAP + F_CORE
    NOOP
    inx
    inx
    jmp unnest

; 
; ok ( w -- w w ) \  
;
HEADER "DUP", "dup", F_LEAP + F_CORE
    NOOP
    dex
    dex
    lda p0 + 2, x
    sta p0 + 0, x
    lda p0 + 3, x
    sta p0 + 1, x
    jmp unnest

; 
; ok ( w1 w2 -- w1 w2 w1 ) \  
;
HEADER "OVER", "over", F_LEAP + F_CORE
    NOOP
    dex
    dex
    lda p0 + 4, x
    sta p0 + 0, x
    lda p0 + 5, x
    sta p0 + 1, x
    jmp unnest

;
;   ok  ( w -- ; -- w )
;   yes, must be placed into second on stack
;
HEADER ">R", "tor", F_LEAP + F_CORE
    NOOP
    dey
    dey
    ; preserve return 
    lda r0 + 2, y
    sta r0 + 0, y
    lda r0 + 3, y
    sta r0 + 1, y
    ; move values
    lda p0 + 0, x
    sta r0 + 2, y
    lda p0 + 1, x
    sta r0 + 3, y
    inx
    inx
    jmp unnest

;
;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R>", "rto", F_LEAP + F_CORE
    NOOP
    dex
    dex
    ; move values
    lda r0 + 2, y
    sta p0 + 0, x
    lda r0 + 3, y
    sta p0 + 1, x
    ; preserve return
    lda r0 + 0, x
    sta r0 + 2, y
    lda r0 + 1, x
    sta r0 + 3, y
    iny
    iny
    jmp unnest

;
;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R@", "rat", F_LEAP + F_CORE
    NOOP
    dex
    dex
    ; move values
    lda r0 + 2, y
    sta p0 + 0, x
    lda r0 + 3, y
    sta p0 + 1, x
    jmp unnest

;
;   ok  ( w1 w2 -- w3 carry )
;
HEADER "UM+", "umplus", F_LEAP + F_CORE
    NOOP
    clc
    lda p0 + 2, x
    adc p0 + 0, x
    sta p0 + 2, x
    lda p0 + 3, x
    adc p0 + 1, x
    sta p0 + 3, x
    ; save carry flag
    lda #0
    sta p0 + 1, x
    adc #0
    sta p0 + 0, x
    jmp unnest

;
;   ok  ( -- w ) \ high byte always $00
;
HEADER "(stor)", "stor", F_LEAP + F_CORE
    NOOP
    dex
    dex
    sta p0 + 0, x
    lda #0
    sta p0 + 1, x
    jmp unnest

;
;   ok  ( -- w )
;
HEADER "SP@", "psat", F_LEAP + F_CORE
    NOOP
    txa
    jmp stor

;
;   ok  ( -- wrk )
;
HEADER "RS@", "rsat", F_LEAP + F_CORE
    NOOP
    tya
    jmp stor

;
;   ok  ( -- 0 )
;
HEADER "0", "zero", F_LEAP + F_CORE
    NOOP
    lda #0
    jmp stor

;
;   ok  ( -- 1 )
;
HEADER "1", "one", F_LEAP + F_CORE
    NOOP
    lda #1
    jmp stor

;
;   ok  ( -- 2 )
;
HEADER "2", "two", F_LEAP + F_CORE
    NOOP
    lda #2
    jmp stor

;
;   ok  ( -- 4 )
;
HEADER "4", "four", F_LEAP + F_CORE
    NOOP
    lda #4
    jmp stor

;
;   ok  ( -- wrk )
;
HEADER "SP!", "psto", F_LEAP + F_CORE
    NOOP
    lda p0 + 0, x
    tax
    jmp unnest

;
;   ok  ( -- wrk )
;
HEADER "RP!", "rsto", F_LEAP + F_CORE
    NOOP
    lda p0 + 0, x
    tay
    jmp unnest

;
;   ok  ( -- ; a -- a )
;   tricky absolute 
HEADER "BRANCH", "branch", F_LEAP + F_CORE
    NOOP
    ; get reference
    lda r0 + 0, y
    sta wrk
    lda r0 + 1, y
    sta wrk + 1
    ; load from
    sty y_save
    ldy #0
    lda (wrk), y
    sta nos
    iny
    lda (wrk), y
    sta nos + 1
    ldy y_save
    ; put reference
    lda nos
    sta r0 + 0, y
    lda nos + 1
    sta r0 + 1, y
    ; done
    jmp unnest

;
;   ok  ( w -- ; a -- a )
;
HEADER "ZBRANCH", "zbranch", F_LEAP + F_CORE
    NOOP 
    lda #0
    cmp p0 + 0, x
    bne nobranch
    cmp p0 + 1, x
    bne nobranch
    jmp branch

;
;   ok  ( -- ;  -- )
;
HEADER "NOBRANCH", "nobranch", F_LEAP + F_CORE
    NOOP
    clc
    lda r0 + 0, y
    adc CELL_SIZE
    sta r0 + 0, y
    bcc @non
    lda r0 + 1, y
    adc #0
    sta r0 + 1, y
@non:
    inx
    inx
    jmp unnest

