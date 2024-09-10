
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

/*

routines for flush flash memory

*/

;---------------------------------------------------------------------
;
;    for easy using spm from optiboot 
;
;    spm instruction uses r31:r30 for address and r1:r0 for data
;
;    when erase or write, r0:r1 is ignored, 
;
;   ATmega8L datasheet, pg 209
;
;   command passed in r24
;
;   in optiboot.c version 8.3 :
;   
;	byte address !!!
; 
;    __boot_rww_enable_short();
;    7fd2:       87 bf           out     0x37, r24       ; 55
;    7fd4:       e8 95           spm
;    7fd6:       08 95           ret
;
;   do not expeculate, only one page to "flash flush"
;   minimal optiboot uses last 256 words at 7e00 ( 3F00 words) 
;   and the sequence: bf 87 95 e8 95 08
;
;   commands are: 
;    0x01 fill buffer, 
;    0x03 erase page, 
;    0x05 write page
;   set SPMCR and do a SPM whithin 4 cycles
;
;    about 3.5 to 4.5 ms to complete write !
;
;---------------------------------------------------------------------


; small trick, in macros.S

; pagesize = (SPM_PAGE - 1)

; pagemask = (~pagesize)

;----------------------------------------------------------------------
;
;   load a flash memory page (fa sa -- )
;   copy one flash page from flash address fa to sram address sa
;
HEADER "(load_flash)", "LDFLASH"
    NOOP

    ; origin in ps

    pspull zpm_low, zpm_high

    ; preserve parameter tack

    rspush psp_low, psp_high

    ; move destin from tos

    movw psp_low, tos_low

    ; adjust address for lpm
    lsr zpm_low
    rol zpm_high

    ; how many bytes
    lds wrk_low, SPM_SIZE

1:
    lpm wrk_high, Z+
    st X+, wrk_high
    dec wrk_low
    brne 1b

; clean house

    rspull psp_low, psp_high

    pspull tos_low, tos_high

    POON

;----------------------------------------------------------------------
;
;   save a flash memory page (sa fa -- )
;   copy one flash page from sram address sa to flash address fa
;   registers exposed are used for optiboot compiled with gcc
;
HEADER "(save_flash)", "SVFLASH"
    NOOP

    ; destin

    movw zpm_low, tos_low ; tos is HERE

    ; origin

    pspull nos_low, nos_high ; nos is FIB0

    ; save psp 

    rspush psp_low, psp_high ; is X index

    ; load for index

    movw psp_low, nos_low

    ; save address 
    rspush zpm_low, zpm_high

;-----------------------------------------------------------------

    ; erase page
    ; r0:r1 is ignored, ATmega8L datasheet, pg 209
    ldi r24, (1<<PGERS) | (1<<SPMEN)
    rcall _does_spm

;-----------------------------------------------------------------

    ; start buffer page address
    
    clr zpm_low
    clr zpm_high

    ; how many bytes, less than 256!
    ldi r23, SPM_SIZE

    ; copy page to buffer, word by word
2:
    ; fill page flash from sram
    ld r0, X+
    ld r1, X+
    ldi r24, (1<<SPMEN)
    rcall _does_spm
    adiw zpm_low, 2
    ; count down
    dec r23
    dec r23
    brne 2b

;-----------------------------------------------------------------

    ; load flash page address

    rspull zpm_low, zpm_high

    ; write page
    ; r0:r1 is ignored, ATmega8L datasheet, pg 209
    ldi r24, (1<<PGWRT) | (1<<SPMEN)
    rcall _does_spm

;-----------------------------------------------------------------
   ; enable
    ldi r24, 0x11
    rcall _does_spm
;-----------------------------------------------------------------

    ; clean house
    rspull psp_low, psp_high
    pspull tos_low, tos_high
    POON

;----------------------------------------------------------------------
;
; wrapper around optiboot code
;
 
; call spm in NWWM
_does_spm:
    cli
    in r2, __SREG__

#ifdef atmega8
; for a atmega8 with optiboot 512b
#define OPTI_DO_SPM_SHORT 0x1fca    ; in bytes
    rcall OPTI_DO_SPM_SHORT
#endif

#ifdef atmega328
; for a atmega328 with optiboot 512b
#define OPTI_DO_SPM_SHORT 0x7fd2    ; in bytes
;#define OPTI_DO_SPM_SHORT 0x3FE9    ; in words
    call OPTI_DO_SPM_SHORT
#endif

    out __SREG__, r2
    sei
; wait for complete
1:  in      r0, 0x37        ; 55
    sbrc    r0, 0
    rjmp    1b
    ret
 
;----------------------------------------------------------------------
/* from optiboot version 8.2 listing, extra comments added
        ;
        ; the code for spm must reside in the NRWW flash
        ;
        ; make TARGET=Atmega8 AVR_FREQ=8000000L BAUD_RATE=9600 LED_START_FLASHES=5 TIMEOUT=2
        ;
        ; static void do_spm(uint16_t address, uint8_t command, uint16_t data)
        ; r24:r25, r22:r23, r20:r21
        ;
        ; Do spm stuff
        ;
        ; do_spm is 1fb0
    1fb0:       fc 01           movw    r30, r24
    1fb2:       0a 01           movw    r0, r20
    1fb4:       67 bf           out     0x37, r22       ; 55
    1fb6:       e8 95           spm
        ;
        ;       keep r1 as zero
        ;
    1fb8:       11 24           eor     r1, r1
        ;
        ; static void boot_spm_busy_wait()
        ;
        ;       loop while not done
    1fba:       07 b6           in      r0, 0x37        ; 55
    1fbc:       00 fc           sbrc    r0, 0
    1fbe:       fd cf           rjmp    .-6             ; 0x1fba <do_spm+0xa>
        ;
        ;       if ( (command & (_BV(PGWRT)|_BV(PGERS))) && (data == 0) )
        ;
    1fc0:       66 70           andi    r22, 0x06       ; 6
    1fc2:       29 f0           breq    .+10            ; 0x1fce <do_spm+0x1e>
    1fc4:       45 2b           or      r20, r21
    1fc6:       19 f4           brne    .+6             ; 0x1fce <do_spm+0x1e>
    ;
        ;       static void boot_rww_enable_short()
        ;
    1fc8:       81 e1           ldi     r24, 0x11       ; 17

THIS IS THE HACK

    1fca:       87 bf           out     0x37, r24       ; 55
    1fcc:       e8 95           spm
        ;
        ;       return
        ;
    1fce:       08 95           ret
*/



