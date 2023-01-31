
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

.addr    _nmi_int  ; NMI vector
.addr    _init     ; Reset vector
.addr    _irq_int  ; IRQ/BRK vector

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
;   reserved one 4k page $8000-$8FFF for I/O 6522VIA 6551CIA
;   external 74hc glue logic for phi2 LOW and address
;   bit mapped as
;       1000 [15-12]    IOS == select IO == 74HC logic
;       XXXX [11-08]    IOS and XXXX == select chip 0-3
;       YYYY [07-04]    IOS and YYYY == select chip 0-3
;       ZZZZ [03-00]    ports in chip
;
; must adjust the address
;
;---------------------------------------------------------------------
;
;   $8000, reserved
;
;---------------------------------------------------------------------
;   $8010, system CIA, select (R0 R1)
;
CIA       =  $8010    ; The base address of the 6551 ACIA.
CIA_DATA  =  CIA+0   ; Its data I/O register
CIA_RX    =  CIA+0   ; Its data I/O register
CIA_TX    =  CIA+0   ; Its data I/O register
CIA_STAT  =  CIA+1   ; Its  status  register
CIA_COMM  =  CIA+2   ; Its command  register
CIA_CTRL  =  CIA+3   ; Its control  register

;---------------------------------------------------------------------
;   $8020, system VIA,  select (R0 R1 R3 R4)
;
VIA0        =  $8020    ; The base address of the 6522 VIA.
VIA0_PB         =  VIA0+0    ; Its port B address
VIA0_PA         =  VIA0+1    ; Its port A address
VIA0_DDRB       =  VIA0+2    ; Its data-direction register for port B
VIA0_DDRA       =  VIA0+3    ; Its data-direction register for port A
VIA0_T1CL       =  VIA0+4    ; Its timer-1 counter's low  byte
VIA0_T1CH       =  VIA0+5    ; Its timer-1 counter's high byte
VIA0_T1LL       =  VIA0+6    ; Its timer-1 latcher's low  byte
VIA0_T1LH       =  VIA0+7    ; Its timer-1 latcher's high byte
VIA0_T2CL       =  VIA0+8    ; Its timer-2 counter's low  byte
VIA0_T2CH       =  VIA0+9    ; Its timer-2 counter's high byte
VIA0_SR         =  VIA0+10   ; The shift register
VIA0_ACR        =  VIA0+11   ; The auxiliary  control register
VIA0_PCR        =  VIA0+12   ; The peripheral control register
VIA0_IFR        =  VIA0+13   ; The interrupt  flag  register
VIA0_IER        =  VIA0+14   ; The interrupt enable register
VIA0_PAH        =  VIA0+15   ; Its port A address no handshake

;---------------------------------------------------------------------
;   $8030, user VIA,  select (R0 R1 R3 R4)
;
VIA1        =  $8030    ; The base address of the 6522 VIA.
VIA1_PB         =  VIA1+0    ; Its port B address
VIA1_PA         =  VIA1+1    ; Its port A address
VIA1_DDRB       =  VIA1+2    ; Its data-direction register for port B
VIA1_DDRA       =  VIA1+3    ; Its data-direction register for port A
VIA1_T1CL       =  VIA1+4    ; Its timer-1 counter's low  byte
VIA1_T1CH       =  VIA1+5    ; Its timer-1 counter's high byte
VIA1_T1LL       =  VIA1+6    ; Its timer-1 latcher's low  byte
VIA1_T1LH       =  VIA1+7    ; Its timer-1 latcher's high byte
VIA1_T2CL       =  VIA1+8    ; Its timer-2 counter's low  byte
VIA1_T2CH       =  VIA1+9    ; Its timer-2 counter's high byte
VIA1_SR         =  VIA1+10   ; The shift register
VIA1_ACR        =  VIA1+11   ; The auxiliary  control register
VIA1_PCR        =  VIA1+12   ; The peripheral control register
VIA1_IFR        =  VIA1+13   ; The interrupt  flag  register
VIA1_IER        =  VIA1+14   ; The interrupt enable register
VIA1_PAH        =  VIA1+15   ; Its port A address no handshake

;---------------------------------------------------------------------
;
;   adapted from http://forum.6502.org/viewtopic.php?f=4&t=5495
;
;---------------------------------------------------------------------

;-------------------------------------------------------------------------------
;   acia_init, configures 19200,N,8,1
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
;   acia_push, transmit a byte thru 6551
;-------------------------------------------------------------------------------

acia_push:
    pha
    lda #$10 		
; wait while full
@loop:
    bit CIA_STAT     	
    beq @loop
; transmit
    pla             	; Pull A from stack
    sta CIA_TX     	; Send A
    ; delay about 521 us (why)
    jsr delay_6551
    rts

;-------------------------------------------------------------------------------
;   acia_pull, receive a byte thru 6551
;-------------------------------------------------------------------------------
acia_pull:
    lda #$08
; wait while empty
@loop:
    bit CIA_STAT	
    beq @loop
; receive
    lda CIA_RX
    rts

;-------------------------------------------------------------------------------
; Delay at least about 0.521 ms
; zzzz must recalcule this 
;	call, 6
;	save, 13
;	sets, 4
;       loop, (2 + 3 + 2 + 3) * 68 * 1 + (68 + 1)
;	load, 16
;	return, 6
;-------------------------------------------------------------------------------
delay_6551:
;  call, 6
; save, 3 + 2 + 3 + 2 + 3, 13 cyc
    pha 
    tya
    pha
    txa
    pha

@delay_loop: ; 2 + 2 
    ldy   #1    ;Get delay value (clock rate in MHz 1 clock cycles)

@delay_y:
    ldx   #$6C    ; Seed X reg for 526 cyc

@delay_x:
    ; (2 + 3 + 2 + 3) * 68 * 1 + (68 + 1)
    dex            ;Decrement low index
    bne @delay_x   ;Loop back until done
    dey            ;Decrease by one
    bne @delay_y   ;Loop until done

; load, 4 + 2 + 4 + 2 + 4, 16
    pla
    tax
    pla
    tay
    pla
; done, 6
    rts       ; return

;------------------------------------------------------------------------------
