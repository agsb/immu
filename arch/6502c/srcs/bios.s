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
;---------------------------------------------------------------------
.IF 0

# Easy BIOS or MOS for a 6502toy

## Memory map
   
    $0100 to $BFFF,  RAM
    
    $C000 to $CFFF,  DEVICES
    
    $D000 to $FFFF,  ROM

### RAM

    $0000 to $00FF page zero, hardware registers
    
    $0100 to $01FF page one, hardware stack
    
    $0200 to $02FF page two, bios buffers
    
    $0300 to $03FF page tri, mapped address for devices and routines
   
    $0400-$BFFF generic use

### DEVICES

    mapped onboard:
  
    $C000   bios exclusive hardware
    
    $C010   bios device 01, acia 6551
    
    $C020   bios device 02,  via 6522
    
    $C030   bios device 03,  via 6522
    
    $C040   external device 04
    
    $C050   external device 04
    
    $C060   external device 04
    
    $C070   external device 04
    
    for expansion:
    
    $C080 to $C0FF, 8 devices mapped outboard

    $C100 to $CFFF, free address 

### ROM
    
    $D000 to $DFFF  4k expansion ROM

    $E000 to $FFFF  8k internal ROM

### Interrupts

    the clock tick done by VIA_T1 is the only NMI of 6502toy.
    
.ENDIF
;---------------------------------------------------------------------
;
;   enable some ca65
;
; enable listing
.list on

; identifiers
.case +

; debug
.debuginfo +

; enable features

.feature c_comments

.feature string_escapes

.feature org_per_seg

; enable 6502 mode

.p02

;---------------------------------------------------------------------
;
;   CONSTANTS
;
;---------------------------------------------------------------------
;   at page zero
;   $F0 to $FF bios reserved 16 bytes
;
bios_void = $F0
bios_lnk = bios_void + $0
bios_not = bios_void + $2  ; pending
bios_cnt = bios_void + $4  ; nested
bios_vec = bios_void + $6  ; resolver
bios_clk = bios_void + $8  ; clock tick

; copycat registers
bios_a = bios_void + $a   ; accumulator
bios_x = bios_void + $b   ; index X
bios_y = bios_void + $c   ; index Y
bios_s = bios_void + $d   ; stack 
bios_p = bios_void + $e   ; status
bios_f = bios_void + $f   ; break flag

;---------------------------------------------------------------------
; at page three
GHOSTS = $0300   

; devices list
DEVICE0 = GHOSTS + $00 ; default $C000
DEVICE1 = GHOSTS + $02 ; default $C010
DEVICE2 = GHOSTS + $04 ; default $C020
DEVICE3 = GHOSTS + $06 ; default $C030
DEVICE4 = GHOSTS + $08 ; default $C040
DEVICE5 = GHOSTS + $0A ; default $C050
DEVICE6 = GHOSTS + $0C ; default $C060
DEVICE7 = GHOSTS + $0E ; default $C070

; pointers list
SEECLCK = GHOSTS + $EE
TSTCHAR = GHOSTS + $F0
PUTCHAR = GHOSTS + $F2
GETCHAR = GHOSTS + $F4
MONITOR = GHOSTS + $F6
COPYCAT = GHOSTS + $F8
NMIVECT = GHOSTS + $FA ; Non Mask Interrupt
RSTVECT = GHOSTS + $FC ; Reset
IRQVECT = GHOSTS + $FE ; Interrupt request

;---------------------------------------------------------------------
; 
DEVICES = $C000

CIA       =  DEVICES+$10    ; The base address of the 6551 ACIA.
CIA_DATA  =  CIA+0   ; Its data I/O register
CIA_RX    =  CIA+0   ; Its data I/O register
CIA_TX    =  CIA+0   ; Its data I/O register
CIA_STAT  =  CIA+1   ; Its  status  register
CIA_COMM  =  CIA+2   ; Its command  register
CIA_CTRL  =  CIA+3   ; Its control  register

VIA        =  DEVICES+$20    ; The base address of the 6522 VIA.
VIA_PB     =  VIA+0    ; Its port B address
VIA_PA     =  VIA+1    ; Its port A address
VIA_DDRB   =  VIA+2    ; Its data-direction register for port B
VIA_DDRA   =  VIA+3    ; Its data-direction register for port A
VIA_T1CL   =  VIA+4    ; Its timer-1 counter's low  byte
VIA_T1CH   =  VIA+5    ; Its timer-1 counter's high byte
VIA_T1LL   =  VIA+6    ; Its timer-1 latcher's low  byte
VIA_T1LH   =  VIA+7    ; Its timer-1 latcher's high byte
VIA_T2CL   =  VIA+8    ; Its timer-2 counter's low  byte
VIA_T2CH   =  VIA+9    ; Its timer-2 counter's high byte
VIA_SR     =  VIA+10   ; The shift register
VIA_ACR    =  VIA+11   ; The auxiliary  control register
VIA_PCR    =  VIA+12   ; The peripheral control register
VIA_IFR    =  VIA+13   ; The interrupt flag register
VIA_IER    =  VIA+14   ; The interrupt enable register
VIA_PAH    =  VIA+15   ; Its port A address no handshake

;----------------------------------------------------------------------
; at $FF00
SHADOWS = $FF00

.segment "SHADOWS"

; references of devices, use downwards
.word    DEVICES+00    ; _bios_hardware
.word    DEVICES+10    ; _cia_one   
.word    DEVICES+20    ; _via_one   
.word    DEVICES+30    ; _via_two 
.word    DEVICES+40    ; extra    
.word    DEVICES+50    ; extra    
.word    DEVICES+60    ; extra    
.word    DEVICES+70    ; extra    

SLACK:  .res 220, $0

; pointers of routines, use upwards
.word acia_pass   ; ec
.word acia_pull   ; ee
.word acia_push   ; f0
.word clock_off   ; f2
.word clock_on    ; f4
.word monitor     ; f6
.word copycat     ; f8

;---------------------------------------------------------------------
; at $FFFA
.segment "VECTORS"

; hardware jumpers
.word _jump_nmi  ; fa ROM NMI vector
.word _jump_rst  ; fc ROM Reset vector
.word _jump_irq  ; fe ROM IRQ/BRK vector

;---------------------------------------------------------------------
;
.segment "ONCE"

;---------------------------------------------------------------------
;
; some code adapted from 
; http://wilsonminesco.com/0-overhead_Forth_interrupts/
; and 6502.org forum
;
;---------------------------------------------------------------------
; interrups stubs, easy way
;   At boot, the $FF00 page is copied to $0300,
;   with default values for devices and routines
;   then all vectors could be changed and could
;   be restored also.
;

; must be at shadow rom copied to ghost ram

_jump_nmi:
    jmp (NMIVECT)

_jump_irq:
    jmp (IRQVECT)

_jump_rst:
    ; jmp (RSTVECT) never do that or hang ever boot
    jmp _rst_init

; void nmi,irq at boot

nmi_init:

bios_init:

    rti

;---------------------------------------------------------------------
;
; reset stub
;
_rst_init:

; real _init:
_init:
    ; disable interrupts
    sei

    ; no BCD math
    cld

    ; copy default vector page
    jsr copycat

    ; setup acia one
    jsr acia_init

    ; setup via one
    jsr via_init 

    ; setup via two 
    ;lda #<(DEVS+20)
    ;sta via_two+0
    ;lda #>(DEVS+20)
    ;sta via_two+1
    ;jsr via_init 

    ; setup clock
    jsr clock_setup

    ; enable interrupts
    
    lda #<_bios_init_easy
    sta IRQVECT+0
    lda #>_bios_init_easy
    sta IRQVECT+1

    lda #<_bios_init_easy
    sta NMIVECT+0
    lda #>_bios_init_easy
    sta NMIVECT+1

    ; stack: pull is decr, push is incr
    ldx #$FF
    txs
    
    ; there we go....
    cli
    jsr _main

_main:

    ; for safety
    jmp _init

;---------------------------------------------------------------------
; copy default vector pag from ROM to RAM
; uses a, x
;
copycat:
    sta bios_a
    lda #$FF
    tax
@copy:    
    lda $FF00, x
    sta $0300, x
    dex
    bne @copy
    rts

;---------------------------------------------------------------------
; coarse delay loop
;
; 7 * dy + 4 * dy * dx + 15
;
; will loop till 256 * 256, 261900 cycles
; (264208 if 8*dy + 4*dy*dx + 16)
; uses a, x, y 
; y = dy, x = dx
;
bios_delay: ; 6
@loop:    
    txa            ; 2 Get delay loop 
@y_delay: 
    tax            ; 2 Get delay loop
@x_delay:
    dex            ; 2
    bne @x_delay   ; 2
    dey            ; 2
    bne @y_delay   ; 2
    rts       ; 6 return

;---------------------------------------------------------------------
monitor:
    rts

;---------------------------------------------------------------------
; real irq handler
; easy minimal 

_bios_init_easy:
    sta bios_a
    pla
    pha
    and #$10
    bne _bios_soft_easy
    
_bios_hard_easy:
    ;
    ; from a hardware interrupt,
    ; must pooling devices to decide 
    ; which caller
    ; do something somewhere sometime
    ;bit VIA_STS
    ;bmi service_via
    ;bit VIA2_STS
    ;bmi service_via2
    ;jmp service_acia

    ;
    ; load registers and return
    lda bios_a
    rti

_bios_soft_easy:
    ;
    ; from a BRK, a software interrupt
    ; which always must be $00 $ZZ
    ; 
    ; the PC in stack minus one is the code $ZZ 
    ; for what break was called.
    ;
    ; do something somewhere sometime
    ;
    ; load registers and return
    lda bios_a
    rti

    
;---------------------------------------------------------------------
;   interrupts stubs, trampolines
;
_bios_handler:
    cld

_bios_save_registers:
    lda bios_a
    pha
    txa
    pha
    tya
    pha
    ; fake jump indirect
    lda #>_bios_load_registers
    pha
    lda #<_bios_load_registers
    pha
    rts

_bios_load_registers:
    pla
    tay
    pla
    tax
    pla
    sta bios_a
    rti

;---------------------------------------------------------------------
;
; clock tick
; phi2 is 0.9216 MHz, 10ms is 9216 or $2400
;
clock_setup:
    ; store counter
    lda #$00
    sta VIA_T1CL
    lda #$24
    sta VIA_T1CH
    ; setup free-run and intrrupt at time-out
    lda VIA_ACR
    and #$7F    ;   %01111111
    ora #$40    ;   %01000000
    sta VIA_ACR

; start clock
clock_on:    
    lda #%11000000
    sta VIA_IER
    rts

; stop clock    
clock_off:
    lda #%10000000
    sta VIA_IER
    rts

; counts ticks
_bios_tick:
    bit VIA_T1CL
    inc bios_clk+0
    bne @ends
    inc bios_clk+1
    bne @ends
    inc bios_clk+2
    bne @ends
    inc bios_clk+3
@ends:
    rti

;count:
;    inc CNT+0
;    bne @ends
;    inc CNT+1
;@ends:
;    rti

;======================================================================
;
;----------------------------------------------------------------------
;
;   $00, system mapped reserved
;

;----------------------------------------------------------------------
;   $10, system CIA, select (R0 R1)
; 
;   uses a, s, x, y must be saved by caller
;
;----------------------------------------------------------------------

;-------------------------------------------------------------------------------
;   acia_init, configures 19200,N,8,1 FIXED
;-------------------------------------------------------------------------------
acia_init:
    pha			; Push A to stack
    lda #0
    sta CIA_STAT
    ; %0001 1110 =  9600 baud, external receiver, 8 bit words, 1 stop bit
    ; %0001 1111 = 19200 baud, external receiver, 8 bit words, 1 stop bit
    lda #$1F     
    sta CIA_CTRL
    ; %0000 1011 = no parity, normal mode, RTS low, INT disable, DTR low 
    lda #$0B     
    sta CIA_COMM
    pla             ; Restore A
    rts

;-------------------------------------------------------------------------------
;   acia_push, transmit a byte thru 6551, receive byte in a
;   waits
;-------------------------------------------------------------------------------
acia_push:
    pha
; wait while full
@loop:
    ldy #$FF
@y_loop:    
    ldx #$FF
@x_loop:    
    lda CIA_STAT
    and #16
    bne @put_char
    dex
    cpx #0
    bne @x_loop
    dey
    cpy #0
    bne @y_loop
    clc
    rts
; transmit
@put_char:
    pla            	; Pull A from stack
    sta CIA_TX     	; Send A
    sec
    rts

;-------------------------------------------------------------------------------
;   acia_pull, receive a byte thru 6551, return byte in a, carry set on ok
;   waits
;-------------------------------------------------------------------------------
acia_pull:
; wait while empty
@loop:
    ldy #$FF
@y_loop:    
    ldx #$FF
@x_loop:    
    lda CIA_STAT
    and #8
    bne @get_char
    dex
    cpx #0
    bne @x_loop
    dey
    cpy #0
    bne @y_loop
    clc
    rts
; receive
@get_char:
    lda CIA_RX
    sec
    rts

;-------------------------------------------------------------------------------
;   acia_pass, verify a 6551, carry set on yes
;   no waits
;-------------------------------------------------------------------------------
acia_pass:
; no wait
@loop:
    sec
    lda CIA_STAT
    and #8
    bne @ends
    clc
@ends:    
    rts

;-------------------------------------------------------------------------------
; Delay at least about 0.521 ms
; 
; for a 0,9216 MHz, using 14 and 19 
;
;-------------------------------------------------------------------------------
acia_delay:
    ldx #14
    ldy #19
    jsr bios_delay
    rts

;=====================================================================
;
;   $20, system VIA,  select (R0 R1 R3 R4)
; 
;   uses a, s, x, y must be saved by caller
;
;-------------------------------------------------------------------------------


;---------------------------------------------------------------------
;
;---------------------------------------------------------------------
via_init:
    rts

;---------------------------------------------------------------------
bios_isr:
	; scan for via
scan_via:
	bit VIA_IFR
	bpl skip_via
	jsr service_via
skip_via:

ends_isr:
	rti

;	attend interrupt 
service_via:
	pha
	lda #$7F
	sta VIA_IFR;
	pla
	rti
; 	default
ret_isr:
	rti

;---------------------------------------------------------------------
; if pool
;
;ISR:
;    bit VIA1_STAT
;    bmi service_via1
;    bit VIA2_STAT
;    bmi service_via2
;    jmp service_acia

;---------------------------------------------------------------------
