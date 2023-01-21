
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
; from http://wilsonminesco.com/6502primer/PgmWrite.html

;---------------------------------------------------------------------
;   $800X ~ $80FX, 16 ACIAs
;
CIA       =  $8000    ; The base address of the 6551 ACIA.
CIAZ	  =  $80F0    ; last
CIA_DATA  =  CIA+0   ; Its data I/O register is at $8000.
CIA_RX    =  CIA+0   ; Its data I/O register is at $8000.
CIA_TX    =  CIA+0   ; Its data I/O register is at $8000.
CIA_STAT  =  CIA+1   ; Its  status  register is at $8001.
CIA_COMM  =  CIA+2   ; Its command  register is at $8002. 
CIA_CTRL  =  CIA+3   ; Its control  register is at $8003.

;---------------------------------------------------------------------
;   $810X ~ $8FFX, 240 VIAs
;
VIA        =  $8100    ; The base address of the 6522 VIA.
VIAZ	   =  $8FF0    ; last
VIA_PB         =  VIA      ; Its port B is at that address.
VIA_PA         =  VIA+1    ; Its port A is at address $A001.
VIA_DDRB       =  VIA+2    ; Its data-direction register for port B is at $8102.
VIA_DDRA       =  VIA+3    ; Its data-direction register for port A is at $8103.
VIA_T2CL       =  VIA+8    ; Its timer-2 counter's low  byte is at $8108.
VIA_T2CH       =  VIA+9    ; Its timer-2 counter's high byte is at $8109.
VIA_SR         =  VIA+10   ; The shift register is at $810A.
VIA_ACR        =  VIA+11   ; The auxiliary  control register is at $810B.
VIA_PCR        =  VIA+12   ; The peripheral control register is at $810C.
VIA_IFR        =  VIA+13   ; The interrupt  flag  register is at $810D.
VIA_IER        =  VIA+14   ; The interrupt enable register is at $810E.

;---------------------------------------------------------------------
;
;   adapted from http://forum.6502.org/viewtopic.php?f=4&t=5495
;
;---------------------------------------------------------------------

;-------------------------------------------------------------------------------
;   Name         ACIA_INIT
;   Desc         Configures base setup
;                   19200,N,8,1
;   Destroys     Nothing
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
;   Name:         ACIA_ECHO
;   Desc:         Sends data to serial port
;   Destroys:     A
;   Note:         TODO - Add fix for 65C51 transmit bug
;                   It was recommended to use ~521 microseconds
;                   (or a little more) delay.
;-------------------------------------------------------------------------------

acia_push:
@loop:
    lda ACIA_STAT     ; Wait for TDRE bit = 1
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
acia_pull:
@loop:
    lda ACIA_STAT             ; Check to see if the buffer is full
    and #$08
    beq @loop
    ; receive
    lda ACIA_RX
    rts

;
; Delay at least about 0.524 ms
; zzzz must recalcule this 
;
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
