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
.segment "VECTORS"

.addr    _nmi_init  ; NMI vector
.addr    _init     ; Reset vector
.addr    _irq_init  ; IRQ/BRK vector

;---------------------------------------------------------------------
;
.segment "ONCE"

;---------------------------------------------------------------------
;
; adapted from 
; http://wilsonminesco.com/0-overhead_Forth_interrupts/
;
;---------------------------------------------------------------------
; interrups stubs
;
_nmi_init:
    ; return
    rti

_irq_init:

    ; save registers
    pha
    tya
    pha
    txa
    pha

    ; copy sp to x
    tsx
    inx     ; x
    inx     ; y
    inx     ; a
    inx     ; p
    lda $0100, x    ; load offset in stack
    and #$10
    bne _irq_soft
    
_irq_hard:
    
    ;
    ; do something somewhere sometime
    ;

    jmp _irq_return

_irq_return:
    ; load registers
    pla
    tax
    pla
    tay
    pla

    ; return 
    rti

_irq_soft:

    ;
    ; do something somewhere sometime
    ;

    jmp _irq_return
    
;---------------------------------------------------------------------
;
; reset stub
;
_init:
    ; disable interrupts
    sei

    ; no BCD math
    cld

    ; clear memory
    lda #0
    tax

@clean: ; page zero, stack, return stack, parameter stack, buffers
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    inx
    bne @clean

    ; setup acia
    jsr acia_init

    ; setup via 
    jsr via_init 

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
    and #10
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
VIA_IFR    =  VIA+13   ; The interrupt  flag  register
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
;---------------------------------------------------------------------
