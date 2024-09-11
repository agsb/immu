
/*
 *  DISCLAIMER
 *
 *  Copyright © 2020, Alvaro Gomes Sobral Barcellos,
 *
 *  Permission is hereby granted, free of charge, to any person obtaining
 *  a copy of this software and associated documentation files (the
 *  "Software"), to deal in the Software without restriction, including
 *  without limitation the rights to use, copy, modify, merge, publish,
 *  distribute, sublicense, and/or sell copies of the Software, and to
 *  permit persons to whom the Software is furnished to do so, subject to
 *  the following conditions:
 *
 *  The above copyright notice and this permission notice shall be
 *  included in all copies or substantial portions of the Software.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 *  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 *  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 *  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 *  LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 *  OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 *  WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 */

;----------------------------------------------------------------------
; review for atmega328
;   10/2022 @agsb


;---------------------------------------------------------------------
; from avr manual, do not change 
; reserved I/O Memory address
;
; FOR AVRs

__SREG__ = 0x3f
__SP_H__ = 0x3e
__SP_L__ = 0x3d

/* USART */
UBRRL = 0x09
UCSRC = 0x20
UCSRB = 0x0a
UCSRA = 0x0b

/* Watch dog */
WDTCR = 0x21

/* timer0 */
TCNT0 = 0x32
TCCR0 = 0x33
TIMSK = 0x39

/* SPMCR */
SPMCR = 0x37

/* SPM BITS */
SPMIE = 7
RWWSB = 6
/* bit 5 reserved */
RWWSRE = 4
BLBSET = 3
PGWRT = 2
PGERS = 1
SPMEN = 0

;----------------------------------------------------------------------
;792486AA–AVR–02/2013 ATmega8(L)Note:1.   See “About Code Examples” on page 8
;
; from atmeg8 datasheet
;
EEARH =  0x1F
EEARL =  0x1E
EEDR  =  0x1D
EECR  =  0x1C
EEWE  =  1
EEMWE =  2
EERE  =  0

;----------------------------------------------------------------------
; sleep register
MCUCR = 0x35 

;----------------------------------------------------------------------
;
;   proto BIOS handler
;
;----------------------------------------------------------------------
;
; code segment, flash
;
.section .text
.org 0x000
.global boot

;----------------------------------------------------------------------
;
; classic interrupt vector table
;
;----------------------------------------------------------------------

boot:

    rjmp RESET ; Reset Handler
    reti ; rjmp EXT_INT0 ; IRQ0 Handler
    reti ; rjmp EXT_INT1 ; IRQ1 Handler
    reti ; rjmp TIM2_COMP ; Timer2 Compare Handler
    reti ; rjmp TIM2_OVF ; Timer2 Overflow Handler
    reti ; rjmp TIM1_CAPT ; Timer1 Capture Handler
    reti ; rjmp TIM1_COMPA ; Timer1 CompareA Handler
    reti ; rjmp TIM1_COMPB ; Timer1 CompareB Handler
    reti ; rjmp TIM1_OVF ; Timer1 Overflow Handler
    rjmp TIM0_OVF ; Timer0 Overflow Handler
    reti ; rjmp SPI_STC ; SPI Transfer Complete Handler
    reti ; rjmp USART_RXC ; USART RX Complete Handler
    reti ; rjmp USART_UDRE ; ((0x0C) + 0x20) Empty Handler
    reti ; rjmp USART_TXC ; USART TX Complete Handler
    reti ; rjmp ADC ; ADC Conversion Complete Handler
    reti ; rjmp EE_RDY ; EEPROM Ready Handler
    reti ; rjmp ANA_COMP ; Analog Comparator Handler
    reti ; rjmp TWSI ; Two-wire Serial Interface Handler
    reti ; rjmp SPM_RDY ; Store Program Memory Ready Handler;

; todo: use USART_RXC to allow ^C, ^D controls

;----------------------------------------------------------------------
; 
RESET:
;   yes, is a nop. allways.
    nop
; clear interrupts
    cli
; init _zero_ as zero
    clr _zero_
    out __SREG__, _zero_ ; clear sreg
; init real sp at end of sram
    ldi r24, lo8(SRAM_END)
    ldi r25, hi8(SRAM_END)
; reserve
    out __SP_L__, r24
    out __SP_H__, r25

;----------------------------------------------------------------------
/*

OSCAL calibration,
from atmel 2555 note:
for atmega8 theorical for 25oC at 5V, value is 168.
for optiboot, value is 143 as sample better for 38400 bauds, maybe less for 40oC
CFLAGS += '-DMAX_TIME_COUNT=F_CPU>>4' '-DOSC_CAL=142' '-DNUM_LED_FLASHES=2' -DBAUD_RATE=38400
*/

;----------------------------------------------------------------------
; init timer0, with internal clock 8MHz, 
;   from gcc public code, io ports as constants
;
; preset of timer0, with internal clock 8MHz ; cycle 64 ; offset 131
; timer cycle * offset / clock = 8k/8M = 1ms
;
; so it counts 125 clocks inside the interrup routines
;
; offset counter 256 - 125 = 131
; but was 8 clocks in routine timer0, 
; then 131 + 12 = 143
OFFSETCNT = 143
;
TIMER0_SET:
; enable pre-escaler
    in r16, TCCR0
    ori r16, (1 << 1) | (1 << 0)
    out TCCR0, r16
; offset counter
    ldi r16, OFFSETCNT
; preserve offset
    mov r3, r16
    out TCNT0, r16
; enable counter
    in r16, TIMSK
    ori r16, (1 << 0) 
    out TIMSK, r16
;   clear click counter
    clr r4
    clr r5

;----------------------------------------------------------------------
; init watch dog, from avr-gcc public code, io ports as constants
; write logical one to WDCE and WDE, set WDP2, WDP1, WDP0 to ~ 2.0 s
;
WATCHDOG_SET:
    in r16, WDTCR
    ori r16, (1 << 4) | (1 << 3)
    ori r16, (1 << 2) | (1 << 1) | (1 << 0)
    out WDTCR, r16

;----------------------------------------------------------------------
; init usart, from avr-gcc public code
;
;   defaults to 9600, 8N1, no control
;
USART_SET:
    clr r16
    out UCSRC, r16
    ldi r16, lo8(52)
    out UBRRL, r16
    in r16, UCSRB
    ori r16, lo8(24)
    out UCSRB, r16
    ldi r16, lo8(-114)
    out UCSRC, r16
    in r16, UCSRC
    ori r16,lo8(64)
    out UCSRC, r16

;----------------------------------------------------------------------
; enable interrupts
GOOD:
    sei
    rjmp COLD 
    rjmp HALT

;----------------------------------------------------------------------
;
;   do not use r0 and r1, both are scratch registers used in internal
;   processor routines spm, mul, des, etc
;
;----------------------------------------------------------------------
;   generics:
;   r2 , save_SREG
;   r3 , offset prescale timer0
;   r4 , counter each 1ms low byte
;   r5 , counter each 1ms high byte
;   r6 , _zero_
;
;   timer0 prescale 
;   for 8 MHz, prescale 64, offset 131, results about 1 ms
;   64 * 125 = 8000 ; 
;   256 - 125 = 131 ; offset for miliseconds
;   plus 12 cycles inside routine
;
;   ticks could count till 65 seconds
;
;   60000 is EA60 aka 1 minute
;
;   when take t1 and t2 at less than 30 secs interval
;
;       dt = t2 - t1; dt += (dt < 0) ? 60 : 0;    
;
; interrupt routine
TIM0_OVF:
; disable interrups
    cli
; save flags
    in r2, __SREG__
; increase counter and also clear 
    inc r4
    brbs BIT_ZERO, TIM0_ADJ
    inc r5
TIM0_ADJ:
    out TCNT0, r3
;  reset watch dog
    wdr
; clear _zero_  
    clr r6
; load flags and return
    out __SREG__, r2
; enable interrups
    sei
    reti

;----------------------------------------------------------------------
;
;   r6 is always _zero_  except when ...
;   
HALT:
    nop
    sei
    ldi r6, 0x80   ; Enable sleep mode
    out MCUCR, r6
    sleep           ; Put MCU in sleep mode
    rjmp RESET

;----------------------------------------------------------------------


