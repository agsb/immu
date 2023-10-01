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
;
;---------------------------------------------------------------------
;
;  system bios reserved 16 bytes
;
syst = $F0
irq_lnk = syst + $0
irq_not = syst + $2  ; pending
irq_cnt = syst + $4  ; nested
irq_vec = syst + $6  ; resolver
irq_clk = syst + $8  ; holder pointer
; copycat registers
irq_a = syst + $a   ; accumulator
irq_x = syst + $b   ; index X
irq_y = syst + $c   ; index Y
irq_s = syst + $d   ; stack 
irq_p = syst + $e   ; status
irq_f = syst + $f   ; break flag

; from page three

VECTORS = $0300    

DEVICE0 = VECTORS + $00
DEVICE1 = VECTORS + $02
DEVICE2 = VECTORS + $04
DEVICE3 = VECTORS + $06
DEVICE4 = VECTORS + $08
DEVICE5 = VECTORS + $0A
DEVICE6 = VECTORS + $0C
DEVICE7 = VECTORS + $0F

SEECLCK = VECTORS + $EE
TSTCHAR = VECTORS + $F0
PUTCHAR = VECTORS + $F2
GETCHAR = VECTORS + $F4
MONITOR = VECTORS + $F6
COPYCAT = VECTORS + $F8
NMIVECT = VECTORS + $FA
RSTVECT = VECTORS + $FC
IRQVECT = VECTORS + $FE


;.org $FF00
.addr    DEVS+00
.addr    DEVS+10    ; _cia_one   
.addr    DEVS+20    ; _via_one   
.addr    DEVS+30    ; _via_two   
.addr    DEVS+40
.addr    DEVS+50
.addr    DEVS+60
.addr    DEVS+70

;.org $FFF0
.segment "VECTORS"

.addr monitor  ; f0
.addr monitor  ; f2
.addr monitor  ; f4
.addr monitor  ; f6
.addr copycat  ; f8
.addr _jump_nmi  ; fa ROM NMI vector
.addr _jump_rst  ; fc ROM Reset vector
.addr _jump_irq  ; fe ROM IRQ/BRK vector

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

_jump_nmi:
    jmp ($03FA)

_jump_irq:
    jmp ($03FE)

_jump_rst:
    jmp _rst_init

; void nmi at boot

nmi_init:
irq_init:
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
    
    lda #<_irq_init_easy
    sta IRQVECT+0
    lda #>_irq_init_easy
    sta IRQVECT+1

    ; stack: pull is decr, push is incr
    ldx #$FF
    txs
    
    ; there we go....
    cli
    jsr _main

    ; for safety
    jmp _init

;---------------------------------------------------------------------
; copy default vector page
; uses a, x
;
copycat:
    sta irq_a
    lda #$FF
    tax
@copy:    
    lda $FF00, x
    sta $0300, x
    dex
    bne @copy
    rts

;---------------------------------------------------------------------
monitor:
    rts

;---------------------------------------------------------------------
; real irq handler
; easy minimal 

_irq_init_easy:
    sta irq_a
    pla
    pha
    and #$10
    bne _irq_soft_easy
    
_irq_hard_easy:
    ;
    ; from a hardware interrupt,
    ; must pooling devices to decide 
    ; which caller
    ; do something somewhere sometime
    ;
    ; load registers and return
    lda irq_a
    rti

_irq_soft_easy:
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
    lda irq_a
    rti

    
;---------------------------------------------------------------------
;   interrupts stubs, trampolines
;
_irq_handler:
    cld

_irq_save_registers:
    lda irq_a
    pha
    txa
    pha
    tya
    pha
    ; fake jump indirect
    lda #>(_irq_load_registers)
    pha
    lda #<(_irq_load_registers)
    pha
    rts

_irq_load_registers:
    pla
    tay
    pla
    tax
    pla
    sta irq_a
    rti

;---------------------------------------------------------------------
;
; clock tick
;
clock_setup:
    lda #0
    sta irq_clk+0
    sta irq_clk+1
    rts

_irq_tick:
    bit VIA_T1CL
    inc irq_clk+0
    bne @ends
    inc irq_clk+1
@ends:
    rti

;=====================================================================
;
;   reserved one 4k page $C000-$CFFF for I/O 6522VIA 6551CIA
;   external 74hc glue logic for phi2 LOW and address
;   bit mapped as
;       1100 [15-12]    IOS == select IO == 74HC logic
;       XXXX [11-08]    IOS and XXXX == select chip 0-3
;       YYYY [07-04]    IOS and YYYY == select chip 0-3
;       ZZZZ [03-00]    ports in chip
;
;   must adjust the address
;
;   adapted from http://forum.6502.org/
;
;---------------------------------------------------------------------
;
;   $C000-$C00F, reserved
;
DEVS = $C000
;---------------------------------------------------------------------
;
;   $00, system mapped reserved
;

;---------------------------------------------------------------------
;   $10, system CIA, select (R0 R1)
; 
;   uses a, s, x, y must be saved by caller
;
;-------------------------------------------------------------------------------

CIA       =  DEVS+$10    ; The base address of the 6551 ACIA.
CIA_DATA  =  CIA+0   ; Its data I/O register
CIA_RX    =  CIA+0   ; Its data I/O register
CIA_TX    =  CIA+0   ; Its data I/O register
CIA_STAT  =  CIA+1   ; Its  status  register
CIA_COMM  =  CIA+2   ; Its command  register
CIA_CTRL  =  CIA+3   ; Its control  register

;-------------------------------------------------------------------------------
;   acia_init, configures 19200,N,8,1 FIXED
;-------------------------------------------------------------------------------
acia_init:
    pha			; Push A to stack
    lda #0
    sta CIA_STAT
    ; %0001 1111 = 19200 baud, external receiver, 8 bit words, 1 stop bit
    lda #$1F     
    sta CIA_CTRL
    ; %0000 1011 = odd parity, parity mode disabled, normal mode, 
    ; RTSB Low, trans int disabled, IRQB disabled, DTRB low
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
;-------------------------------------------------------------------------------
; 
;   for a 0,9216 MHz, must be: 282 cycles, 282 - 48 = 234
;   using 14 and 19 for delay loops
;
;	call, 6
;	sets, 4
;   loop, (2 + 3 + 2 + 3) * x * y
;	return, 6
;
;-------------------------------------------------------------------------------
acia_delay:
@loop: 
    ldy   #14  ; Get delay loop 
@y_delay:
    ldx   #19  ; Get delay loop
@x_delay:
    dex            
    bne @x_delay   
    dey            
    bne @y_delay   
    rts       ; return

;=====================================================================
;
;   $20, system VIA,  select (R0 R1 R3 R4)
; 
;   uses a, s, x, y must be saved by caller
;
;-------------------------------------------------------------------------------

VIA        =  DEVS+$20    ; The base address of the 6522 VIA.
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

;---------------------------------------------------------------------
;
;---------------------------------------------------------------------
via_init:
    rts

;---------------------------------------------------------------------
irq_isr:
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
