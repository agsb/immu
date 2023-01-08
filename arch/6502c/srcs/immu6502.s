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
;---------------------------------------------------------------------
;
;   04/01/2023   please read the Notes.md
;
;---------------------------------------------------------------------
;   enable some ca65  
;
; enable listing
.list on

; enable 6502 mode
.p02

;---------------------------------------------------------------------
; 
;   defines

.define VERSION "0.01.02"

.define EQU =

.define TIMES .time

;---------------------------------------------------------------------
;
.macro commentsto
.if 0 
.endmacro

.macro endcommentsto
.endif
.endmacro

;---------------------------------------------------------------------
; 
;   ancient borrow
NULL    = $0000

;   6502 hardware
ZPAGE   = $000
STACK   = $100

;   logical flags, forth 83
FALSE   = $0000
TRUE    = $FFFF

;   buffer sizes
TIB_SIZE  = 80
PAD_SIZE  = 72

;   cell is 16 bits, 2 bytes, common
CELL_SIZE = 2

;   maximum word size, not standart
WORD_SIZE = 15

;   default base
BASE_DEFAULT = 16

;---------------------------------------------------------------------
;   forth dictionary:
;
;   | link | size + flags | name + pad | code ~~~ ends |
;
;   link, .word, link to previous forth 
;   size+flags, .byte, size of name (1 - 15)
;   name+pad, .bytes, characters of name (+pad)  
;   code, .words, array of code or references
;   ends, .word, jump or reference to unnest
;
;---------------------------------------------------------------------
;
;   forth words flags
; 
F_RESERVED  = $80
F_IMMEDIATE = $40
F_COMPILE   = $20
F_HIDDEN    = $10

F_TOMASK = $F0
F_UNMASK = $0F

;   not really flags but nice look at listings
F_LEAP = $00   ; for primitives
F_CORE = $00   ; for core words

;---------------------------------------------------------------------
;
;   minimal error codes from forth 2012
;   2's complement
;
NO_ERROR = 0
INVALID_MEMORY  = $FFF7     ; -9
OUT_OF_RANGE    = $FFF5     ; -11
INVALID_WORD    = $FFF3     ; -13
TO_READ_ONLY    = $FFEC     ; -20
NOT_A_NUMBER    = $FFE8     ; -24

;---------------------------------------------------------------------
;   ASCII constants
;
;   Flow Control
;   assumes that all line edit is done at remote!
;   just a static line, receives a line until a CR or CR LF
;   uses BS, for edit last char
;
ESC_    =   27    ; ascii escape ^[
XON_    =   17    ; ascii DC1 ^Q
XOFF_   =   19    ; ascii DC3 ^S

CR_     =   13    ; ascci carriage return ^M
LF_     =   10    ; ascii line feed ^J
BS_     =    8    ; ascii backspace ^H

BL_     =   32    ; ascii space
QT_     =   34    ; ascii double quotes \"

;=====================================================================
;   macros generic

_link_ .set NULL
_last_ .set NULL

;---------------------------------------------------------------------
.macro typestring display, string
    jsr display
    .byte str1 - str0
str0:
    .byte string
str1:
.endmacro

;---------------------------------------------------------------------
.macro makelabel arg1, arg2
.ident(.concat(arg1, arg2)):
.endmacro

;---------------------------------------------------------------------
.macro HEADER name, label, flags, leaf

.ifblank leaf
    .out " No leaf "
.endif
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

;
;   6502 cpu is byte unit
;    .align 2, $00  

    _last_ .set *
    .word _link_
    .byte .strlen(name) + ( F_RESERVED | flags ) + 0
    .byte name
;
;   6502 cpu is byte unit
;    .align 2, $20

    _link_ .set _last_

;   All primitives (leafs) must start with NULL
.ifnblank leaf 
    .word NULL
.endif 

makelabel "", label

.endmacro

;---------------------------------------------------------------------
;   task or process states
.enum
    HALT    = 0
    IDLE    = 1
    WAIT    = 2
    BUSY    = 3
.endenum

;---------------------------------------------------------------------
;   need page zero for indirect address
;
.segment "ZP"

reserved:   .res 240

;---------------------------------------------------------------------
; pseudo registers
tos = $00F0
nos = tos + 2
wrk = tos + 4

; copycat
a_save = tos + 6
s_save = tos + 7
x_save = tos + 8
y_save = tos + 9
p_save = tos + 10
h_save = tos + 11

;---------------------------------------------------------------------
;   system
;   irq mask stuff
irqnot = tos + 12  ; pending
irqcnt = tos + 13  ; nested
irqvec = tos + 14  ; resolver

;---------------------------------------------------------------------
; parameter stack, $0200
p0 = $0200
pz = $02FF
;---------------------------------------------------------------------
; return stack, $0300
r0 = $0300
rz = $03FF

;---------------------------------------------------------------------
; terminal input buffer, $0400
t0 = $0400
tz = t0 + TIB_SIZE

;---------------------------------------------------------------------
; math reserved
m0 = tz + 2 
m1 = tz + 4
m2 = tz + 6 
m3 = tz + 8
m4 = tz + 10
m5 = tz + 12
m6 = tz + 14
m7 = tz + 16

;---------------------------------------------------------------------
; forth 
radx = tz + 18   ; base radix for numbers
stat = tz + 20   ; interpreter state
last = tz + 22   ; link to dictionary latest word
dp = tz +  24  ; pointer to dicionary next free cell

;dsk = tz + 26   ; disk number
;blk = tz + 28   ; block number (track)
;sct = tz + 30   ; sector number
;scr = tz + 32   ; screen number

;csp = tz + 34  ; hold stack
;hnd = tz + 36  ; hold handler
;hld = tz + 38  ; holder
;tmp = tz + 40  ; scratch

;---------------------------------------------------------------------
;
.segment "VECTORS"

.addr    _nmi_int  ; NMI vector
.addr    _init     ; Reset vector
.addr    _irq_int  ; IRQ/BRK vector

;---------------------------------------------------------------------
;
.segment "ONCE"

_init:
    ; disable interrupts
    sei

    ; no BCD math
    cld

    ; clear memory
    lda #0
    ldx #0

@clean:
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    inx
    bne @clean

    ; offset stacks
    ldy #$FF
    ldx #$FF
    txs

    ; enable interrupts
    cli
    
    ;
    jsr _main

;=====================================================================
;
;   reserved one 4k page $2000-$2FFF for I/O 6522VIA 6551CIA
;   external 74hc glue logic for phi2 LOW and address
;       0010 [15-12]    IOS == select IO
;       XXXX [11-08]    IOS and XXXX == select chip 0-3
;       YYYY [07-04]    IOS and YYYY == select chip 0-3
;       ZZZZ [03-00]    port in chip

;---------------------------------------------------------------------
;
;   adapted from: http://forum.6502.org/viewtopic.php?f=4&t=5495
;
;---------------------------------------------------------------------
;
;   CIA 6551, just one
;
ACIA        = $2000
ACIA_CTRL   = ACIA + 3
ACIA_CMD    = ACIA + 2
ACIA_SR     = ACIA + 1
ACIA_RX     = ACIA
ACIA_TX     = ACIA

;-------------------------------------------------------------------------------
;   Name:         ACIA_INIT
;   Desc:         Configures base setup
;                   19200,N,8,1
;   Destroys:     Nothing
;-------------------------------------------------------------------------------
acia_init:
    pha			; Push A to stack
    lda #$1F     ; %0001 1111 = 19200 Baud
            ;              External receiver
            ;              8 bit words
            ;              1 stop bit
    sta ACIA_CTRL
    lda #$0B     ; %0000 1011 = Receiver odd parity check
            ;              Parity mode disabled
            ;              Receiver normal mode
            ;              RTSB Low, trans int disabled
            ;              IRQB disabled
            ;              Data terminal ready (DTRB low)
    sta ACIA_CMD
    pla             ; Restore A
    rts

;-------------------------------------------------------------------------------
;   Name:         ACIA_ECHO
;   Desc:         Sends data to serial port
;   Destroys:     A
;   Note:         TODO - Add fix for 65C51 transmit bug
;                   It was recommended to use ~521 microseconds
;                   (or a little more) delay.
;-------------------------------------------------------------------------------

acia_echo:
    pha             ; Push A to stack
@loop:
    lda ACIA_SR     ; Wait for TDRE bit = 1
    and #$10        ; 16, %00010000
    beq @loop
    pla             ; Pull A from stack
    ; send
    sta ACIA_TX     ; Send A
    ; delay
    jsr delay_6551
    rts

;-------------------------------------------------------------------------------
;   Name:         ACIA_READ
;   Desc:         Reads data from serial port and return in A
;   Destroys:     A
;   Note:         Probably not compatible with EhBASIC because it is
;                 blocking
;-------------------------------------------------------------------------------
acia_read:
    lda #$08
@loop:
    bit ACIA_SR             ; Check to see if the buffer is full
    beq @loop
    ; receive
    lda ACIA_RX
    rts

; Latest WDC 65C51 has a bug - Xmit bit in status register is stuck on
; IRQ driven transmit is not possible as a result - interrupts are endlessly triggered
; Polled I/O mode also doesn't work as the Xmit bit is polled - delay routine is the only option
; The following delay routine kills time to allow W65C51 to complete a character transmit
; 0.523 milliseconds required loop time for 19,200 baud rate
; MINIDLY routine takes 524 clock cycles to complete - X Reg is used for the count loop
; Y Reg is loaded with the CPU clock rate in MHz (whole increments only) and used as a multiplier
;
; zzzz must recalcule this 
;
delay_6551:
; save
    pha
    tya
    pha
    txa
    pha
@delay_loop:
;    ldy   #2    ;Get delay value (clock rate in MHz 2 clock cycles)
    ldy   #1    ;Get delay value (clock rate in MHz 1 clock cycles)

@delay_y:
    ldx   #$68    ;Seed X reg
@delay_x:
    dex   	    ;Decrement low index
    bne @delay_x   ;Loop back until done
    dey     	  ;Decrease by one
    bne @delay_y   ;Loop until done
; load
    pla
    tax
    pla
    tay
    pla
; done
    rts       ; return

;=====================================================================
;
.segment "CODE"

;---------------------------------------------------------------------
; interrups stubs
;
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
    lda STACK, x
    and #$10
    bne _break
    
    ;
    ; do something somewhere sometime
    ;

_irq:
    ; load registers
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

;======================================================================
;
; adapted from 
; http://wilsonminesco.com/0-overhead_Forth_interrupts/
;
; zzzz not finished
;
; next: 
;   ldy irqnot
;   beq runISR
;   ...
;   bcs inc_hi
;   jmp wrk - 1
;
;inc_hi:
;   inc nos + 1
;   jmp wrk - 1
;
HEADER "IRQOK", "IRQOK", F_LEAP, LEAF
    cli
    ; continue
    jmp unnest

HEADER "NOIRQ", "NOIRQ", F_LEAP, LEAF
    sei
    ; continue
    jmp unnest

HEADER "SYSRTI", "SYSRTI", F_LEAP, LEAF
    sei
    lda irqnot
    beq noi
    cli
noi:
    ; continue
    jmp unnest

HEADER "IRQOK?", "IRQOKQ", F_LEAP, LEAF
    php
    pla
    and #4
    beq irqf
    jmp FFALSE
irqf: 
    jmp FTRUE

runISR:
    inc irqnot
    jmp (irqvec)

irqroute:
    jmp (irqvec)

setirq:
    sta a_save
    ; clear byte irq flag
    lda #0
    sta irqnot
    ; set bit 4 flag
    pla
    ora #4
    pha
    lda a_save
    rti

;======================================================================


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

;======================================================================
;
;---------------------------------------------------------------------
; inner address interpreter, using MITC
; classic ITC, nos == IP, wrk == WR
;
HEADER "ENDS", "ends", F_LEAP, LEAF 
unnest:
    ; pull from return stack
    lda r0 + 0, y
    sta nos + 0
    lda r0 + 1, y
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
    adc #2
    sta nos + 0
    bne @end
    inc nos + 1
@end:

jump:
    ; in MICT, all leafs start with NULL
    ; in 6502 non code at page zero
    lda #0
    cmp wrk + 1
    bne nest
    ; non forth word at page zero
    jmp (nos)

nest:
    ; push into return stack
    dey
    dey
    lda nos + 1
    sta r0 + 1, y
    lda nos + 0
    sta r0 + 0, y

link:
    ; next reference
    lda wrk + 0
    sta nos + 0
    lda wrk + 1
    sta nos + 1
    jmp next

;---------------------------------------------------------------------
; 
; ok ( -- false )
;
HEADER "FALSE", "FFALSE", F_LEAP + F_CORE, LEAF
    lda #$00
    jmp fflag

; 
; ok ( -- true )
;
HEADER "TRUE", "FTRUE", F_LEAP + F_CORE, LEAF
    lda #$FF
    jmp fflag

fflag:
    inx
    inx
    sta p0 + 0, x
    sta p0 + 1, x
    ; continue
    jmp unnest

false2:
    dex
    dex

false1:
    dex
    dex
    jmp ffalse

true2:
    dex
    dex

true1:
    dex
    dex
    jmp ftrue

; 
; ok ( w -- false | true ) \ test w = 0
;
HEADER "0=", "ZEQU", F_LEAP + F_CORE, LEAF
    lda #0
    cmp p0 + 0, x
    bne false1
    cmp p0 + 1, x
    bne false1
    beq true1

; 
; ok ( w -- false | true ) \ test w < 0
;
HEADER "0<", "ZLESS", F_LEAP + F_CORE, LEAF
    lda #0
    cmp p0 + 0, x
    bcc false1
    cmp p0 + 1, x
    bcc false1
    beq true1

; 
; 
; ok ( w1 w2  -- false | true ) \ test w1 > w2
;
HEADER "=", "EQU", F_LEAP + F_CORE, LEAF
    lda p0 + 2, x
    cmp p0 + 0, x
    bne flase2
    lda p0 + 3, x
    cmp p0 + 1, x
    bne flase2
    beq true2 

; 
; ok ( w1 w2  -- false | true ) \ test w1 > w2
;
HEADER "<", "LESS", F_LEAP + F_CORE, LEAF
    lda p0 + 2, x
    cmp p0 + 0, x
    bcs false2
    lda p0 + 3, x
    cmp p0 + 1, x
    bcs false2
    bcc true2

; 
; ok ( w1 -- w2 ) \  rotate left
;
HEADER "2*", "SHL", F_LEAP + F_CORE, LEAF
    ; preserve high bit zzzz
    clc
    rol p0 + 0, x
    rol p0 + 1, x
    ; continue
    jmp unnest

; 
; ok ( w1 -- w2 ) \  rotate right
;
HEADER "2/", "SHR", F_LEAP + F_CORE, LEAF
    clc
    ror p0 + 1, x
    ror p0 + 0, x
    ; continue
    jmp unnest

; 
; ok ( w1 w2  -- w3 ) \  w1 XOR w2
;
HEADER "NEGATE", "INOT", F_LEAP + F_CORE, LEAF
    lda #FF
    eor p0 + 0, x
    sta p0 + 0, x
    eor p0 + 1, x
    sta p0 + 3, x
    jmp unnest

; 
; ok ( w1 w2  -- w3 ) \  w1 + w2
;
HEADER "+", "PLUS", F_LEAP + F_CORE, LEAF
    clc
    lda p0 + 2, x
    adc p0 + 0, x
    sta p0 + 2, x
    lda p0 + 3, x
    adc p0 + 1, x
    sta p0 + 3, x
    jmp DROP

; 
; ok ( w1 w2  -- w3 ) \  w1 - w2
;
HEADER "-", "MINUS", F_LEAP + F_CORE, LEAF
    sec
    lda p0 + 2, x
    sbc p0 + 0, x
    sta p0 + 2, x
    lda p0 + 3, x
    sbc p0 + 1, x
    sta p0 + 3, x
    jmp DROP

; 
; ok ( w1 w2  -- w3 ) \  w1 AND w2
;
HEADER "AND", "IAND", F_LEAP + F_CORE, LEAF
    lda p0 + 2, x
    and p0 + 0, x
    sta p0 + 2, x
    lda p0 + 3, x
    and p0 + 1, x
    sta p0 + 3, x
    jmp DROP

; 
; ok ( w1 w2  -- w3 ) \  w1 OR w2
;
HEADER "OR", "IOR", F_LEAP + F_CORE, LEAF
    lda p0 + 2, x
    ora p0 + 0, x
    sta p0 + 2, x
    lda p0 + 3, x
    ora p0 + 1, x
    sta p0 + 3, x
    jmp DROP

; 
; ok ( w1 w2  -- w3 ) \  w1 XOR w2
;
HEADER "XOR", "IXOR", F_LEAP + F_CORE, LEAF
    lda p0 + 2, x
    eor p0 + 0, x
    sta p0 + 2, x
    lda p0 + 3, x
    eor p0 + 1, x
    sta p0 + 3, x
    jmp DROP

; 
; ok ( w -- ) \  
;
HEADER "DROP", "DROP", F_LEAP + F_CORE, LEAF
    inx
    inx
    ; continue
    jmp unnest

; 
; ok ( w -- w w ) \  
;
HEADER "DUP", "DUP", F_LEAP + F_CORE, LEAF
    dex
    dex
    lda p0 + 2, x
    sta p0 + 0, x
    lda p0 + 3, x
    sta p0 + 1, x
    ; continue
    jmp unnest

; 
; ok ( w1 w2 -- w1 w2 w1 ) \  
;
HEADER "OVER", "OVER", F_LEAP + F_CORE, LEAF
    dex
    dex
    lda p0 + 4, x
    sta p0 + 0, x
    lda p0 + 5, x
    sta p0 + 1, x
    ; continue
    jmp unnest

;
;   ok  ( w -- ; -- w )
;   yes, must be placed into second on stack
;
HEADER ">R", "TOR", F_LEAP + F_CORE, LEAF
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
    ; continue
    jmp unnest

;
;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R>", "RTO", F_LEAP + F_CORE, LEAF
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
    ; continue
    jmp unnest

;
;   ok  (  -- w1 ; w1 -- )
;   yes, must be taken from second on stack
;
HEADER "R@", "RAT", F_LEAP + F_CORE, LEAF
    dex
    dex
    ; move values
    lda r0 + 2, y
    sta p0 + 0, x
    lda r0 + 3, y
    sta p0 + 1, x
    ; continue
    jmp unnest

;
;   ok  ( w1 w2 -- w3 carry )
;
HEADER "UM+", "UMPLUS", F_LEAP + F_CORE, LEAF
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
    ; continue
    jmp unnest

;
;   ok  ( w1 w2 -- w3 carry )
;   zzzz
HEADER "UM*", "UMSTAR", F_LEAP + F_CORE, LEAF
    clc
    ; continue
    jmp unnest

;
;   ok  ( w1 w2 -- w3 carry )
;   zzzz
HEADER "UM/MOD", "UMSLASHMOD", F_LEAP + F_CORE, LEAF
    clc
    ; continue
    jmp unnest

;
;   ok  ( -- w ) \ high byte always $00
;   push with high byte cleared
HEADER "(stor)", "stor", F_LEAP + F_CORE, LEAF
    dex
    dex
    sta p0 + 0, x
    lda #0
    sta p0 + 1, x
    ; continue
    jmp unnest

;
;   ok  ( -- w )
;
HEADER "SP@", "PSAT", F_LEAP + F_CORE, LEAF
    txa
    jmp stor

;
;   ok  ( -- wrk )
;
HEADER "RS@", "RSAT", F_LEAP + F_CORE, LEAF
    tya
    jmp stor

;
;   ok  ( -- 0 )
;
HEADER "0", "ZERO", F_LEAP + F_CORE, LEAF
    lda #0
    jmp stor

;
;   ok  ( -- 1 )
;
HEADER "1", "ONE", F_LEAP + F_CORE, LEAF
    lda #1
    jmp stor

;
;   ok  ( -- 2 )
;
HEADER "2", "TWO", F_LEAP + F_CORE, LEAF
    lda #2
    jmp stor

;
;   ok  ( -- 4 )
;
HEADER "4", "FOUR", F_LEAP + F_CORE, LEAF
    lda #4
    jmp stor

;
;   ok  ( -- CR )   \ ascii carriage return
;
HEADER "CR", "CR", F_LEAP + F_CORE, LEAF
    lda #13
    jmp stor

;
;   ok  ( -- LF )   \ ascii line feed
;
HEADER "LF", "LF", F_LEAP + F_CORE, LEAF
    lda #10
    jmp stor

;
;   ok  ( -- BL )   \ ascii blank space
;
HEADER "BL", "BL", F_LEAP + F_CORE, LEAF
    lda #32
    jmp stor

;
;   ok  ( -- wrk )
;
HEADER "SP!", "PSTO", F_LEAP + F_CORE, LEAF
    lda p0 + 0, x
    tax
    jmp DROP 

;
;   ok  ( -- wrk )
;
HEADER "RP!", "RSTO", F_LEAP + F_CORE, LEAF
    lda p0 + 0, x
    tay
    jmp DROP

;
;   ok  ( -- ; a -- a )
;   tricky absolute 
HEADER "BRANCH", "BRANCH", F_LEAP + F_CORE, LEAF
    ; get reference
    lda r0 + 0, y
    sta nos
    lda r0 + 1, y
    sta nos + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda (nos), y
    sta r0 + 0, y
    ; copy msb
    iny
    lda (nos), y
    sta r0 + 1, y
    ; load index
    ldy y_save
    ; continue
    jmp unnest

;
;   ok  ( w -- ; a -- a )
;
HEADER "ZBRANCH", "ZBRANCH", F_LEAP + F_CORE, LEAF
    lda #0
    cmp p0 + 0, x
    bne NOBRANCH
    cmp p0 + 1, x
    bne NOBRANCH
    inx
    inx
    jmp BRANCH

;
;   ok  ( -- ;  -- )
;
HEADER "NOBRANCH", "NOBRANCH", F_LEAP + F_CORE, LEAF
    clc
    lda r0 + 0, y
    adc CELL_SIZE
    sta r0 + 0, y
    bcc @non
    lda r0 + 1, y
    adc #1
    sta r0 + 1, y
@non:
    jmp DROP

;
;   ok  ( w -- ; a -- a )
;
HEADER "LIT", "LIT", F_LEAP + F_CORE, LEAF
    ; get reference
    dex
    dex
    lda r0 + 0, y
    sta p0 + 0, x
    lda r0 + 1, y
    sta p0 + 1, x
    ; tricky extra :)
    dex
    dex
    jmp NOBRANCH

;
;   ok  ( w -- ; a -- a )
;
HEADER "@", "AT", F_LEAP + F_CORE, LEAF
    ; load address
    lda p0 + 0, x
    sta nos + 0
    lda p0 + 1, x
    sta nos + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda (nos), y
    sta p0 + 0, x
    ; copy msb
    iny
    lda (nos), y
    sta p0 + 1, x
    ; load index
    ldy y_save
    ; continue
    jmp unnest

;
;   ok  ( w -- ; a -- a )
;
HEADER "!", "TO", F_LEAP + F_CORE, LEAF
    ; load address
    lda p0 + 0, x
    sta nos + 0
    lda p0 + 1, x
    sta nos + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda p0 + 2, x
    sta (nos), y
    ; copy msb
    iny
    lda p0 + 3, x
    sta (nos), y
    ; load index
    ldy y_save
    ; 2drop
    inx 
    inx
    jmp DROP 
    
;
;   ok  ( w -- ; a -- a )
;
HEADER "C@", "CAT", F_LEAP + F_CORE, LEAF
    ; load address
    lda p0 + 0, x
    sta nos + 0
    lda p0 + 1, x
    sta nos + 1
    ; save index
    sty y_save
    ; copy lsb
    ldy #0
    lda (nos), y
    sta p0 + 0, x
    ; clear msb
    lda #0
    sta p0 + 1, x
    ; load index
    ldy y_save
    ; continue
    jmp unnest

;
;   ok  ( w -- ; a -- a )
;
HEADER "C!", "CTO", F_LEAP + F_CORE, LEAF
    ; load address
    lda p0 + 0, x
    sta nos + 0
    lda p0 + 1, x
    sta nos + 1
    ; save index
    sty y_save
    ; copy only lsb
    ldy #0
    lda p0 + 2, x
    sta (nos), y
    ; load index
    ldy y_save
    ; continue
    jmp unnest
    
; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "1+", "PLUS1", F_LEAP + F_CORE, LEAF
    clc
    lda #1
    adc p0 + 0, x
    sta p0 + 0, x
adcs:
    lda #0
    adc p0 + 1, x
    sta p0 + 1, x
    ; continue
    jmp unnest

; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "2+", "PLUS2", F_LEAP + F_CORE, LEAF
    clc
    lda #2
    adc p0 + 0, x
    sta p0 + 0, x
    jmp adcs

; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "4+", "PLUS4", F_LEAP + F_CORE, LEAF
    clc
    lda #4
    adc p0 + 0, x
    sta p0 + 0, x
    jmp adcs

; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "1-", "MINUS1", F_LEAP + F_CORE, LEAF
    sec
    lda #1
    sbc p0 + 0, x
    sta p0 + 0, x
sbcs:
    lda #0
    sbc p0 + 1, x
    sta p0 + 1, x
    ; continue
    jmp unnest

; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "2-", "MINUS2", F_LEAP + F_CORE, LEAF
    sec
    lda #2
    sbc p0 + 0, x
    sta p0 + 0, x
    jmp sbcs

; 
; ok ( w1  -- w2 ) \  w1 + 1
;
HEADER "4-", "MINUS4", F_LEAP + F_CORE, LEAF
    sec
    lda #4
    sbc p0 + 0, x
    sta p0 + 0, x
    jmp sbcs

; 
; ok (  -- cell )
;
HEADER "CELL", "CELL", F_LEAP + F_CORE, LEAF
    jmp two

; 
; ok (  -- cell )
;
HEADER "CELL+", "CELLPLUS", F_LEAP + F_CORE, LEAF
    jmp plus2

; 
; ok (  -- cell )
;
HEADER "CELL-", "CELLMINUS", F_LEAP + F_CORE, LEAF
    jmp minus2

; 
; ok ( w1 w2 -- w2 w1 )
;
HEADER "SWAP", "SWAP", F_LEAP + F_CORE, LEAF
    ; 2d to nos
    lda p0 + 0, x
    sta nos + 0
    lda p0 + 1, x
    sta nos + 1
    ; 1d to 2d
    lda p0 + 2, x
    sta p0 + 0, x
    lda p0 + 3, x
    sta p0 + 1, x
    ; nos to 1d
    lda nos + 0, x
    sta p0 + 2, x
    lda nos + 1, x
    sta p0 + 3, x
    ; continue
    jmp unnest

; 
; ok ( w1 w2 w3 -- w2 w3 w1 )
;
HEADER "ROT", "ROT", F_LEAP + F_CORE, LEAF
    ; 3d to nos
    lda p0 + 5, x
    sta nos + 0
    lda p0 + 6, x
    sta nos + 1
    ; 2d to 3d
    lda p0 + 3, x
    sta p0 + 5, x
    lda p0 + 4, x
    sta p0 + 6, x
    ; 1d to 2d
    lda p0 + 2, x
    sta p0 + 4, x
    lda p0 + 3, x
    sta p0 + 5, x
    ; nos to 1d
    lda nos + 0, x
    sta p0 + 0, x
    lda nos + 1, x
    sta p0 + 1, x
    ; continue
    jmp unnest

;==============================================================================   
; 
; adapted from
; from: https://dwheeler.com/6502/ummod.txt
; 
; The following is Garth Wilson's corrected UM/MOD code for Forth,
; compared to the buggy fig-Forth, per
; http://6502.org/source/integers/ummodfix/ummodfix.htm
; 
;   ok    ( ud u -- rem quot )
;
HEADER "UM/MOD", "UMMOD", F_LEAP + F_CORE, LEAF
         sec
         lda  p0 + 2, x    ; Subtract hi cell of dividend by
         sbc  p0 + 0, x    ; divisor to see if there's an overflow condition.
         lda  p0 + 3, x
         sbc  p0 + 1, x
         bcs  oflow        ; Branch if /0 or overflow.
 
         lda  #11H         ; Loop 17x.
         sta  nos          ; Use N for loop counter.

  loop:  rol  p0 + 4, x    ; Rotate dividend lo cell left one bit.
         rol  p0 + 5, x
         dec  nos          ; Decrement loop counter.
         beq  endw         ; If we're done, then branch to end.
         rol  p0 + 2, x    ; Otherwise rotate dividend hi cell left one bit.
         rol  p0 + 3, x
         lda  #0
         sta  nos + 1
         rol  nos + 1      ; Rotate the bit carried out of above into N+1.
 
         sec
         lda  p0 + 2, x    ; Subtract dividend hi cell minus divisor.
         sbc  p0 + 0, x
         sta  nos + 2      ; Put result temporarily in N+2 (lo byte)
         lda  p0 + 3, x
         sbc  p0 + 1, x
         sta  nos + 3      ; and Y (hi byte).
         lda  nos + 1      ; Remember now to bring in the bit carried out above.
         sbc  #0
         bcc  loop
 
         lda  nos + 2      ; If that didn't cause a borrow,
         sta  p0 + 2, x    ; make the result from above to
         lda  nos + 3
         sta  p0 + 3, x    ; be the new dividend hi cell
         bcs  loop         ; and then brach up. (NMOS 6502 can use BCS here.)
 
  oflow: lda  #FFH         ; If overflow or /0 condition found,
         sta  p0 + 2, x    ; just put FFFF in both the remainder
         sta  p0 + 3, x
         sta  p0 + 4, x    ; and the quotient.
         sta  p0 + 5, x
 
  endw:  inx           ; When you're done, show one less cell on data stack,
         inx           ; (INX INX is exactly what the Forth word DROP does) 
         jmp  SWAP     ; and swap the two top cells to put quotient on top.
                       ; (Actually you'll jump to the beginning of SWAP's
                       ; executable code.  Assembler label "SWAP" is at SWAP's
                       ; PFA, not the CFA that ' SWAP would give you in Forth.

;------------------------------------------------------------------------------
;
HEADER "U*", "USTAR", F_LEAP + F_CORE, LEAF
          LDA p0 + 2, x
          STA N
          STY p0 + 2, x
          LDA p0 + 3, x
          STA N + 1
          STY p0 + 3, x
          LDY #16        ; for 16 bits
L396      ASL p0 + 2, x
          ROL p0 + 3, x
          ROL p0 + 0, x
          ROL p0 + 1, x
          BCC L411
          CLC
          LDA N
          ADC p0 + 2, x
          STA p0 + 2, x
          LDA N + 1
          ADC p0 + 3, x
          STA p0 + 3, x
          LDA #0
          ADC p0 + 0, x
          STA p0 + 0, x
00624
L411      DEY
          BNE L396
          JMP NEXT

HEADER "U/", "USLASH, F_LEAP + F_CORE, LEAF
          LDA p0 + 4, x
          LDY p0 + 2, x
          STY p0 + 4, x
          ASL A
          STA p0 + 2, x
          LDA p0 + 5, x
          LDY p0 + 3, x
          STY p0 + 5, x
          ROL A
          STA p0 + 3, x
          LDA #16
          STA N
L433      ROL p0 + 4, x
          ROL p0 + 5, x
          SEC
          LDA p0 + 4, x
          SBC p0 + 0, x
          TAY
          LDA p0 + 5, x
          SBC p0 + 1, x
          BCC L444
          STY p0 + 4, x
          STA p0 + 5, x
L444      ROL p0 + 2, x
          ROL p0 + 3, x
          DEC N
          BNE L433
          JMP POP
