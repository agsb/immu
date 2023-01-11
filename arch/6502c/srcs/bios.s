;---------------------------------------------------------------------

;.import _halt, _main

;---------------------------------------------------------------------
;
.segment "VECTORS"

;.org $FFFA

.addr    _nmi_int  ; NMI vector
.addr    _init     ; Reset vector
.addr    _irq_int  ; IRQ/BRK vector

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
ACIA       =  $8000    ; The base address of the 6551 ACIA.
ACIA_DATA  =  ACIA+0   ; Its data I/O register is at $8000.
ACIA_RX    =  ACIA+0   ; Its data I/O register is at $8000.
ACIA_TX    =  ACIA+0   ; Its data I/O register is at $8000.
ACIA_STAT  =  ACIA+1   ; Its  status  register is at $8001.
ACIA_COMM  =  ACIA+2   ; Its command  register is at $8002. 
ACIA_CTRL  =  ACIA+3   ; Its control  register is at $8003.

;---------------------------------------------------------------------
VIA        =  $8100    ; The base address of the 6522 VIA.
PB         =  VIA      ; Its port B is at that address.
PA         =  VIA+1    ; Its port A is at address $A001.
DDRB       =  VIA+2    ; Its data-direction register for port B is at $8102.
DDRA       =  VIA+3    ; Its data-direction register for port A is at $8103.
T2CL       =  VIA+8    ; Its timer-2 counter's low  byte is at $8108.
T2CH       =  VIA+9    ; Its timer-2 counter's high byte is at $8109.
SR         =  VIA+10   ; The shift register is at $810A.
ACR        =  VIA+11   ; The auxiliary  control register is at $810B.
PCR        =  VIA+12   ; The peripheral control register is at $810C.
IFR        =  VIA+13   ; The interrupt  flag  register is at $810D.
IER        =  VIA+14   ; The interrupt enable register is at $810E.

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
    sta ACIA_CTRL
    ; %0000 1011 = odd parity, parity mode disabled, normal mode, 
    ; RTSB Low, trans int disabled, IRQB disabled, DTRB low
    lda #$0B     
    sta ACIA_COMM
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
acia_read:
    lda #$08
@loop:
    bit ACIA_STAT             ; Check to see if the buffer is full
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
;    ldy   #2    ;Get delay value (clock rate in MHz 2 clock cycles)
    ldy   #1    ;Get delay value (clock rate in MHz 1 clock cycles)

@delay_y:
;    ldx   #$68    ; original Seed X reg
    ldx   #$6C    ; Seed X reg for 526 cyc
@delay_x:
    ; (2 + 3 + 2 + 3) * 68 * 1 + (68 + 1)
    dex   	    ;Decrement low index
    bne @delay_x   ;Loop back until done
    dey     	  ;Decrease by one
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
