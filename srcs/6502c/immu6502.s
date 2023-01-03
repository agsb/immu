;
;   enable some as65 
;
; enable C like comments
.feature c_comments
; enable listing
.list on
; enable 6502 mode
.p02
; lines per page
.pagelength 66


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
; /* Notes:
; 
; -   source for used with cc65 in Linux
; -   almost adapted from fig-forth-6502, from W. B. Ragsdale
; -   minimized use of pages, zero and one, for use external libraries
; -   minimuzed use of page
; -   all stuff use absolute address and jmps, 
; -   bare minimal use real stack pointer SP 
; -   bare minimal use jsr/rts for relative BIOS
; -   16 bits pseudo registers as in SWEET16, DS, RS, T, N, W, C
; -   stacks goes downwards, uses X and Y for index
; 
; 
; Notes:
; 
; 1. I know that will be not the most fastest code possible.
;   
;     Why ?
;     Most of page zero indexed access uses 3 cycles and 
;         absolute indexed access uses 4 cycles.
;     Not using Accumulator as Top of Stack, just as accumulator (as is).
; 
; 2. the 6502C pages:
; 
; $0000 0x00FF page zero,  reserved for indexed acess
; $0100 0x01FF page one,   reserved for SP use
; 
; $0200 0x02FF page two,   data parameter stack, indexed by X, offset wraps
; $0300 0x03FF page three, return address/parameter stack, indexed by Y, offset wraps
; 
; $0400 0x04FF page four, forth internal registers and buffers 
; $0500 0x0FFF free 3072 bytes SRAM, BIOS buffers, 
; 
; $1000  page forth :)
; 
; $8000  start of ROM (FLASH) BIOS, IOS, Forth
; 
; 3. the MITC inner interpreter
;     R> >R R@ must use the second cell at return stack to load/save values
; 
; 
; */
 
 
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
FALSE   = $00
TRUE    = $FF

; buffer sizes
TIBZ    = 80
PADZ    = 72

; cell is 16 bits, 2 bytes
CELL_SIZE = 2

; maximum word size
WORD_SIZE = 15

; default base
BASE_DEFAULT = 16

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
INVALID_MEMORY = -9
OUT_OF_RANGE = -11
INVALID_WORD = -13
TO_READ_ONLY = -20
NOT_A_NUMBER = -24

;---------------------------------------------------------------------
; ASCII constants
;
; Flow Control
; assumes that all line edit is done at remote!
; just a static line.
; works as a screen or block, just receives a line till a CR or CR LF
; uses BS, for edit last char
;
XON_    =   $11    ; ascii DC1 ^Q
XOFF_   =   $13    ; ascii DC3 ^S

CR_     =   $0d    ; ascci carriage return ^M
LF_     =   $0a    ; ascii line feed ^J
BS_     =   $08    ; ascii backspace ^H

BL_     =   $20    ; ascii space
QT_     =   $22    ; ascii double quotes \"



;---------------------------------------------------------------------
; macros generic

_link_ .set $0
_last_ .set $0

.macro HEADER name, label, flags
.ident (.concat("is_",label)):
    .align 2, $00
    _last_ .set *
    .word _link_
    .byte .strlen(name) + flags
    .byte name
    .align 2, $20
    _link_ .set _last_
label:
.endmacro

.macro NOOP
    .word $0000
.endmacro

;---------------------------------------------------------------------
; need 8 bytes at page zero for indirect address
;
.segment "PZ"
.org $0000

none: .word
ip: .word #$0000
wk: .word #$0000

;---------------------------------------------------------------------
.segment "DATA"
.org $0400

void:   .word NULL
stack:  .word $0100

; pseudo registers
ps:     .word $0200
rs:     .word $0300
tos:    .word NULL
nos:    .word NULL
wrk:    .word NULL
cnt:    .word NULL

; copycat
ar:     .byte $00
pr:     .byte $00
sr:     .byte $00
xr:     .byte $00
yr:     .byte $00

;---------------------------------------------------------------------
.segment "CODE"

.org $8000

BOOT:
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
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x
    inx
    bne :-

    ; offset stacks
    ldy #$FF
    ldx #$FF
    txs

    ; stack reference absolute
    ; high bytes
    lda $02
    sta ps + 1
    lda $03
    sta rs + 1
    ; low bytes
    lda $00
    sta ps
    sta rs
    
nmi:
    ; save registers
    pha
    txa
    pha
    tya
    pha
    ; load registers
    pla
    tay
    pla
    tax
    pla
    ; 
    rti

COLD:
WARM:
TIME:
WATCH:

TURN:
REST:
QUIT:


;---------------------------------------------------------------------
HEADER "ENDS", "ends", F_LEAP 
    NOOP
unnest:
    lda rs + 0, y
    sta nos
    lda rs + 1, y
    sta nos + 1
    iny
    iny
    ; jmp next

next:
    sty yr
    pha
    lda (nos)
    sta wrk
    
    inc nos
    bne :+
    inc nos + 1
    :
    lda (nos)
    sta wrk + 1

    inc nos
    bne :+
    inc nos + 1
    :

leaf:
    lda #0
    cmp wrk + 1
    bne next
    ; none forth word at page zero
    ; cmp W
    ; bne next
    ; all leafs start with $0000
    jmp (nos)

nest:
    dey
    dey
    lda nos
    sta rs + 0, y
    lda nos + 1
    sta rs + 1, y

    lda wrk
    sta nos 
    lda wrk + 1
    sta nos + 1
    jmp next

HEADER "FALSE", "FFALSE", F_LEAP + F_CORE
    NOOP
    lda #0
    jmp fflag

HEADER "TRUE", "FTRUE", F_LEAP + F_CORE
    NOOP
    lda #$FF
    jmp fflag

HEADER "(flag)", "fflag", F_LEAP + F_CORE
    NOOP
    sta ps + 0, x
    sta ps + 1, x
    jmp unnest

HEADER "0=", "zequ", F_LEAP + F_CORE
    NOOP
    lda #0
    cmp ps + 0, x
    bne FFALSE
    cmp ps + 1, x
    bne FFALSE
    beq FTRUE

HEADER "0<", "zless", F_LEAP + F_CORE
    NOOP
    lda #0
    cmp ps + 0, x
    bcc FFALSE
    cmp ps + 1, x
    bcc FFALSE
    beq FTRUE

HEADER "<", "less", F_LEAP + F_CORE
    NOOP
    lda ps + 2, x
    cmp ps + 0, x
    bcs FFALSE
    lda ps + 3, x
    cmp ps + 1, x
    bcs FFALSE
    beq FTRUE

HEADER "+", "plus", F_LEAP + F_CORE
    NOOP
    clc
    lda ps + 2, x
    adc ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    adc ps + 1, x
    sta ps + 3, x
    jmp drop

HEADER "-", "minus", F_LEAP + F_CORE
    NOOP
    sec
    lda ps + 2, x
    sbc ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    sbc ps + 1, x
    sta ps + 3, x
    jmp drop

HEADER "AND", "iand", F_LEAP + F_CORE
    NOOP
    lda ps + 2, x
    and ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    and ps + 1, x
    sta ps + 3, x
    jmp drop

HEADER "OR", "ior", F_LEAP + F_CORE
    NOOP
    lda ps + 2, x
    or ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    or ps + 1, x
    sta ps + 3, x
    jmp drop

HEADER "XOR", "ixor", F_LEAP + F_CORE
    NOOP
    lda ps + 2, x
    eor ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    eor ps + 1, x
    sta ps + 3, x
    jmp drop

HEADER "2*", "shl", F_LEAP + F_CORE
    NOOP
    clc
    rol ps + 0, x
    rol ps + 1, x
    jmp unnest

HEADER "2/", "shr", F_LEAP + F_CORE
    NOOP
    clc
    ror ps + 1, x
    ror ps + 0, x
    jmp unnest

HEADER "DROP", "drop", F_LEAP + F_CORE
    NOOP
    inx
    inx
    jmp unnest

HEADER "DUP", "dup", F_LEAP + F_CORE
    NOOP
    dex
    dex
    lda ps + 2, x
    sta ps + 0, x
    lda ps + 3, x
    sta ps + 1, x
    jmp unnest

HEADER "OVER", "over", F_LEAP + F_CORE
    NOOP
    dex
    dex
    lda ps + 4, x
    sta ps + 0, x
    lda ps + 5, x
    sta ps + 1, x
    jmp unnest

;   ok  ( w1 -- ; -- w1 )
;   yes, must be placed into second on stack
;
HEADER ">R", "tor", F_LEAP + F_CORE
    NOOP
    dey
    dey
    ; preserve return 
    lda rs + 2, y
    sta rs + 0, y
    lda rs + 3, y
    sta rs + 1, y
    ; move values
    lda ps + 0, x
    sta rs + 2, y
    lda ps + 1, x
    sta rs + 3, y
    jmp drop

;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R>", "rto", F_LEAP + F_CORE
    NOOP
    dex
    dex
    ; move values
    lda rs + 2, y
    sta ps + 0, x
    lda rs + 3, y
    sta ps + 1, x
    ; preserve return
    lda rs + 0, x
    sta rs + 2, y
    lda rs + 1, x
    sta rs + 3, y
    iny
    iny
    jmp unnest
    
;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R@", "rat", F_LEAP + F_CORE
    NOOP
    dex
    dex
    ; move values
    lda rs + 2, y
    sta ps + 0, x
    lda rs + 3, y
    sta ps + 1, x
    jmp unnest


;   ok  ( w1 w2 -- w3 carry )
;
HEADER "UM+", "rat", F_LEAP + F_CORE
    NOOP
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
    jmp unnest


;   ok  ( -- w )
;
HEADER "(stor)", "stor", F_LEAP + F_CORE
    NOOP
    dex
    dex
    sta ps + 0, x
    lda #0
    sta ps + 1, x
    jmp unnest

;   ok  ( -- w )
;
HEADER "SP@", "psat", F_LEAP + F_CORE
    NOOP
    txa
    jmp stor

;   ok  ( -- w )
;
HEADER "RS@", "rsat", F_LEAP + F_CORE
    NOOP
    tya
    jmp stor

;   ok  ( -- 0 )
;
HEADER "0", "zero", F_LEAP + F_CORE
    NOOP
    lda #0
    jmp stor

;   ok  ( -- 1 )
;
HEADER "1", "one", F_LEAP + F_CORE
    NOOP
    lda #1
    jmp stor

;   ok  ( -- 2 )
;
HEADER "2", "two", F_LEAP + F_CORE
    NOOP
    lda #2
    jmp stor

;   ok  ( -- 4 )
;
HEADER "4", "four", F_LEAP + F_CORE
    NOOP
    lda #4
    jmp stor

;   ok  ( -- w )
;
HEADER "SP!", "psto", F_LEAP + F_CORE
    NOOP
    lda ps + 0, x
    tax
    jmp unnest

;   ok  ( -- w )
;
HEADER "RP!", "rsto", F_LEAP + F_CORE
    NOOP
    lda ps + 0, x
    tay
    jmp unnest

;   ok  ( -- ; w -- )
;
HEADER "BRANCH", "branch", F_LEAP + F_CORE
    NOOP
    lda rs + 0, y
    sta w
    lda rs + 1, y
    sta w + 1
    jmp (w)

;   ok  ( -- ; w -- )
;
HEADER "ZBRANCH", "zbranch", F_LEAP + F_CORE
    NOOP
    lda #0
    cmp ps + 0, x
    bne nobranch
    cmp ps + 1, x
    bne nobranch
    jmp brancah

;   ok  ( -- ; w -- )
;
HEADER "NOBRANCH", "nobranch", F_LEAP + F_CORE
    NOOP
    clc
    lda rs + 0, y
    adc CELL_SIZE
    sta rs + 0, y
    bcc @non
    lda rs + 1, y
    inc a
    sta rs + 1, y
@non:
    jmp unnest

