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
;  *  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
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
; -   all stuff use absolute address and jumps, 
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
;         Most of page zero indexed access uses 3 cycles and 
;             absolute indexed access uses 4 cycles.
;         Not using Accumulator as Top of Stack, just as accumulator (as is).
; 
; 2. the 6502C pages:
; 
; 0x0000 0x00FF page zero,  reserved for indexed acess
; 0x0100 0x01FF page one,   reserved for SP use
; 
; 0x0200 0x02FF page two,   data parameter stack, indexed by X, offset wraps
; 0x0300 0x03FF page three, return address/parameter stack, indexed by Y, offset wraps
; 
; 0x0400 0x04FF page four, forth internal registers and buffers 
; 0x0500 0x0FFF free 3072 bytes SRAM, BIOS buffers, 
; 
; 0x1000  page forth :)
; 
; 0x8000  start of ROM (FLASH) BIOS, IOS, Forth
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
NULL    EQU 0x0000

; logical flags, forth 83
FALSE   EQU 0x00
TRUE    EQU 0xFF

; buffer sizes
TIBZ    EQU 80
PADZ    EQU 72

; cell is 16 bits
CELL_SIZE = 2

; maximum word size
WORD_SIZE = 15

; default base
BASE_DEFAULT = 16

; forth words flags
;
F_RESERVED = 0x80
F_IMMEDIATE = 0x40
F_COMPILE = 0x20
F_HIDDEN = 0x10

F_TOMASK = 0xF0
F_UNMASK = 0x0F

; not flags but usefull to remember at listings
F_LEAP = 0x00   ; for primitives
F_CORE = 0x00   ; for core words

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
XON_    =   0x11    ; ascii DC1 ^Q
XOFF_   =   0x13    ; ascii DC3 ^S

CR_     =   0x0d    ; ascci carriage return ^M
LF_     =   0x0a    ; ascii line feed ^J
BS_     =   0x08    ; ascii backspace ^H

BL_     =   0x20    ; ascii space
QT_     =   0x22    ; ascii double quotes \"



;---------------------------------------------------------------------
; macros generic

.macro  operation OPC
    lda ps + 0, x
    OPC ps + 2, x
    sta ps + 2, x
    lda ps + 1, x
    OPC ps + 3, x
    sta ps + 3, x
    inx
	inx
	jump unnest
.endmacro

_link_ = 0x0

.macro HEADER name, label, flags=0x0
is_\label:
        .align 2, 0x00
@10:
        .word _link_
        .byte .strlen(name) + flags
        .byte name
        .align 2, 0x20
_link_ = @10
\label:
.endmacro

.global _link_

.segment "DATA"
.orig 0x0400

void:   .word NULL
stack:  .word 0x0100

; pseudo registers
ps:     .word 0x0200
rs:     .word 0x0300
tos:    .word NULL
nos:    .word NULL
wrk:    .word NULL
cnt:    .word NULL

; copycat
ar:     .byte 0x00
pr:     .byte 0x00
sr:     .byte 0x00
xr:     .byte 0x00
yr:     .byte 0x00

;---------------------------------------------------------------------
.segment "CODE"

.org $8000

BOOT:
        sei
        ; no decimal BCD math
        cld         
        ; offset stacks
        lda 0xFF
        tay
        tax
        txs
        ; stack reference fixed
        ; low bytes
        lda 0x00
        sta ps
        sta rs
        ; high bytes
        lda 0x02
        sta ps + 1
        lda 0x03
        sta rs + 1
COLD:
WARM:
TIME:
WATCH:

TURN:
REST:
QUIT:


;---------------------------------------------------------------------
HEADER "ENDS", "ENDS", F_LEAP 

HEADER "FALSE", "FFALSE", F_LEAP | F_CORE
    lda #$00
    jump fflag

HEADER "TRUE", "FTRUE", F_LEAP | F_CORE
    lda #$FF
    jump fflag

HEADER "(flag)TRUE", "fflag", F_LEAP | F_CORE
    sta ps + 0, x
    sta ps + 1, x
    jump _unnest_

HEADER "0=", "zequ", F_LEAP | F_CORE
    lda #$00
    cmp ps + 0, x
    bne FFALSE
    cmp ps + 1, x
    bne FFALSE
    beq FTRUE

HEADER "0<", "zless", F_LEAP | F_CORE
    lda #$00
    cmp ps + 0, x
    bcc FFALSE
    cmp ps + 1, x
    bcc FFALSE
    beq FTRUE

HEADER "<", "less", F_LEAP | F_CORE
    lda ps + 2, x
    cmp ps + 0, x
    bcs FFALSE
    lda ps + 3, x
    cmp ps + 1, x
    bcs FFALSE
    beq FTRUE

HEADER "+", "plus", F_LEAP | F_CORE
    clc
    lda ps + 2, x
    adc ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    adc ps + 1, x
    sta ps + 3, x
    jump drop

HEADER "-", "minus", F_LEAP | F_CORE
    sec
    lda ps + 2, x
    sbc ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    sbc ps + 1, x
    sta ps + 3, x
    jump drop

HEADER "AND", "and", F_LEAP | F_CORE
    lda ps + 2, x
    AND ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    AND ps + 1, x
    sta ps + 3, x
    jump drop

HEADER "OR", "or", F_LEAP | F_CORE
    lda ps + 2, x
    OR ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    OR ps + 1, x
    sta ps + 3, x
    jump drop

HEADER "XOR", "xor", F_LEAP | F_CORE
    lda ps + 2, x
    EOR ps + 0, x
    sta ps + 2, x
    lda ps + 3, x
    EOR ps + 1, x
    sta ps + 3, x
    jump drop

HEADER "2*", "shl", F_LEAP | F_CORE
    clc
    rol ps + 0, x
    rol ps + 1, x
    jump unnest

HEADER "2/", "shr", F_LEAP | F_CORE
    clc
    ror ps + 1, x
    ror ps + 0, x
    jump unnest

HEADER "DROP", "drop", F_LEAP | F_CORE
    inx
    inx
    jump unnest

HEADER "DUP", "dup", F_LEAP | F_CORE
    dcx
    dcx
    lda ps + 2, x
    sta ps + 0, x
    lda ps + 3, x
    sta ps + 1, x
    jump unnest

HEADER "OVER", "over", F_LEAP | F_CORE
    dcx
    dcx
    lda ps + 4, x
    sta ps + 0, x
    lda ps + 5, x
    sta ps + 1, x
    jump unnest

;   ok  ( w1 -- ; -- w1 )
;   yes, must be placed into second on stack
;
HEADER ">R", "tor", F_LEAP | F_CORE
    dcy
    dcy
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
    inx
    inx
    jump unnest

;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R>", "rto", F_LEAP | F_CORE
    dcx
    dcx
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
    jump unnest
    
;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R@", "rat", F_LEAP | F_CORE
    dcx
    dcx
    ; move values
    lda rs + 2, y
    sta ps + 0, x
    lda rs + 3, y
    sta ps + 1, x
    jump unnest


;   ok  ( w1 w2 -- w3 carry )
;
HEADER "UM+", "rat", F_LEAP | F_CORE
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
    jump unnest


;   ok  ( -- w )
;
HEADER "(stor)", "stor", F_LEAP | F_CORE
    dcx
    dcx
    sta ps + 0, x
    lda #0
    sta ps + 1, x
    jump unnest

;   ok  ( -- w )
;
HEADER "SP@", "psat", F_LEAP | F_CORE
    txa
    jump stor

;   ok  ( -- w )
;
HEADER "RS@", "rsat", F_LEAP | F_CORE
    tya
    jump stor

;   ok  ( -- 0 )
;
HEADER "0", "zero", F_LEAP | F_CORE
    lda #0
    jump stor

;   ok  ( -- 1 )
;
HEADER "1", "one", F_LEAP | F_CORE
    lda #1
    jump stor

;   ok  ( -- 2 )
;
HEADER "2", "two", F_LEAP | F_CORE
    lda #2
    jump stor

;   ok  ( -- w )
;
HEADER "SP!", "psto", F_LEAP | F_CORE
    lda ps + 0, x
    tax
    jump unnest

;   ok  ( -- w )
;
HEADER "RP!", "rsto", F_LEAP | F_CORE
    lda ps + 0, x
    tay
    jump unnest

