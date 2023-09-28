;
; 09/2023 agsb@ adaec from http://wilsonminesco.com/6502primer/SPI.ASM
;
; Note:  Added 12/12/20:  After the first part which is for the 65SIB, I added some code for simultaneous sending and receiving
; over SPI, and you specify the SPI mode, 0, 1, 2, or 3.  I adapted it from code supplied by Mauizio Neri.  It looks good but I
; have not run it, so email me if you see any problems, or even if you have an improvement in mind.  This new section starts at
; line 195.  wilsonmines@dslextreme.com


; This code goes with the SPI / 65SIB circuit at http://wilsonminesco.com/6502primer/potpourri.html#BITBANG_SPI .
; This assembly code file is a translation of my working Forth code to run the 65SIB for a fixture with an LCD and an SST25VF032B
; 4Mx8 flash memory in a tiny SO-8 package.  Both were 3.3V, so I had to add voltage translators.  I'm using SPI mode 0 here.  The
; fixture takes two 65SIB addresses.  Only the general SPI code is included here, not the code that was particular to these devices.
; This translation is not tested, but should be pretty dependable.  At least you can see what needs to be done.
; SPI can operate at full duplex, where each clock pulse advances a bit both receiving and transmitting at the same time.  The
; devices I used for this project didn't have any need to do that, so I did not write a routine for doing both simultaneously.
; It is possible to write software to operate the port for all SPI modes, various related protocols, any desired number of bits per
; frame, etc., and to handle things like the autoconfiguration and related intelligence that 65SIB allows but in no way requires.
; Again, the 65SIB spec is at http://forum.6502.org/viewtopic.php?t=1064&start=105 .

; MOSI  is on VIA3PB1
; MISO  is on VIA3PB6
; CLK   is on VIA3PB0
; CONF\ is on VIA3PA7  (The LCD and flash don't use the actual config\, but without interfering w/ its intended operation, we can
;                      use the line for the register-select bit on the LCD and the HOLD\ bit on the flash.  Normally hi on flash.)
; CSx\  is on VIA3PB bits 2, 3, and 4.
;   If the graphic LCD & flash fixture is the first 65SIB device, then the flash is at address 2 and the LCD is at 1.
;   De-sel all 7 is xxx000xx on VIA3PB, selecting device 1 (flash) is xxx001xx, and selecting device 2 (LCD) is xxx010xx.




INIT_65SIB:                   ; Leaves 65SIB interrupts disabled.
        LDA  #11000000B       ; Make VIA3PA6 an output for disabling 65SIB IRQ,
        TSB  VIA3DDRA         ; and  VIA3PA7 an output for 65SIB CONFIG\.

        LDA  VIA3PA
        ORA  #10000000B       ; Output a 1 on CONFIG\ (bit 7)
        AND  #10111111B       ; and a 0 on bit 6 to disable 65SIB IRQs.
        STA  VIA3PA

        LDA  VIA3DDRB         ; Make VIA3PB6 an  input for MISO,
        ORA  #00011111B       ; VIA3PB4, 3, and 2 outputs to the '138 for CS\'s,
        AND  #10111111B       ; VIA3PB1 an output for MOSI, and
        STA  VIA3DDRB         ; VIA3PB0 an output for CLK.

        LDA  #00011111B       ; Write 0's to the '138 to de-select all 65SIB devices,
        TRB  VIA3PB           ; and to the clock and MOSI lines.

        RTS
 ;------------------

EN_65SIB_IRQ:                 ; (These two are used so seldom and are so short
        LDA  #01000000B       ;  that you might want to just make them macros.)
        TSB  VIA3PA
        RTS
 ;------------------

NO_65SIB_IRQ:
        LDA  #01000000B
        TRB  VIA3PA
        RTS
 ;------------------

SELECT: PHA                   ; Start with device number in A.  It must be in the range of 0-7.  No error-checking.
           LDA  #00011100B
           TRB  VIA3PB        ; First, de-select anything else that might have been selected.
        PLA
        ASL  A
        ASL  A                ; Shift left two bit places, to get the 0-7 into bits 2, 3, and 4.
        TSB  VIA3PB
        RTS
 ;------------------

NONE_SELECT:                  ; De-select anything that might have been selected.
        LDA  #00011100B
        TRB  VIA3PB
        RTS
 ;------------------

CLK_UP: MACRO                 ; NOTE!  Accum is not preserved!
        LDA  #1
        TSB  VIA3PB
        ENDM
 ;------------------

CLK_DN: MACRO                 ; NOTE!  Accum is not preserved!
        LDA  #1
        TRB  VIA3PB
        ENDM
 ;------------------

CLK_LO_PULSE: MACRO           ; NOTE!  Clock must already be known to be high!
         DEC  VIA3PB
         INC  VIA3PB
         ENDM
 ;------------------

CLK_HI_PULSE: MACRO           ; NOTE!  Clock must already be known to be low!
         INC  VIA3PB
         DEC  VIA3PB
         ENDM
 ;------------------

MOSI_UP: MACRO                ; NOTE!  Accum is not preserved!
         LDA  #2
         TSB  VIA3PB
         ENDM
 ;------------------

MOSI_DN: MACRO                ; NOTE!  Accum is not preserved!
         LDA  #2
         TRB  VIA3PB
         ENDM
 ;------------------

CONF_UP: MACRO                ; NOTE!  Accum is not preserved!
         LDA  #80H
         TSB  VIA3PA
         ENDM
 ;------------------

COMF_DN: MACRO                ; NOTE!  Accum is not preserved!
         LDA  #80H
         TRB  VIA3PA
         ENDM
 ;------------------

 ; For SEND_BYT and RCV_BYT below, I use program structures discussed in my web page
 ; http://wilsonminesco.com/StructureMacros/ .  The source code for implementing them on the C32 assembler is at
 ; http://wilsonminesco.com/StructureMacros/STRUCMAC.ASM , but you can undoubtedly see what they will assemble
 ; if you want to do it without the macros.  I used them here to make it more clear what is happening.


SEND_BYT:                     ; Start with byte in A.  Slave must already be selected.
    PHA                       ; Put the input number on the stack because we need A for the TRB/TSB mask below.
        CLK_DN                ; Prepare for mode-0 transmit, and for high clock pulse with INC DEC.
        TSX                   ; Put the stack pointer in X for shifting below without bringing it back into the accum.
        LDA  #2               ; 2 is the value of the MOSI bit for TSB & TRB.
        FOR_Y  8, DOWN_TO, 0  ; 8 is the number of bits we will shift out and test in the loop.
            ASL  101,X        ; Shift the input number left, since transmission is msb-first.
            IF_C_CLR          ; The bit gets put in the carry flag.
                TRB  VIA3PB   ; If the bit was a 0,  clear the MOSI bit in VIA3PB,
            ELSE_             ; otherwise
                TSB  VIA3PB   ; (ie, the bit was a 1), set the MOSI bit in VIA3PB.
            END_IF
            CLK_HI_PULSE      ; Pulse the clock line.  The INC/DEC does not affect A.
        NEXT_Y                ; Decr the counter and see if we need to repeat the loop.
    PLA                       ; Remove the number from the stack.  (We don't need it anymore, but we need the stack cleaned up.)
    RTS
 ;------------------

 ; Here's an alternate way to do SEND_BYT that does not use Y as a counter but instead starts by setting the carry flag as a 9th
 ; bit and rotating it in, and using it later to know when to quit looping.  It's from Jeff Laughton's suggestion on the forum,
 ; at http://forum.6502.org/viewtopic.php?p=31942#p31942.  It's also very slightly faster than the version above.

SEND_BYT:
    PHA                       ; The input number will get shifted and rotated while on the stack.
        CLK_DN                ; (CLK_DN leaves A=1)
        TSX
        INA                   ; Turns the 1 above into the 2 needed for the mask for TSB/TRB below.
        SEC                   ; Set a "9th bit" which is only used to know when to quit looping.
        ROL  101,X
        BEGIN
            IF_CARRY_SET
               TSB  VIA3PB
            ELSE
               TRB  VIA3PB
            END_IF
            CLK_HI_PULSE
            ASL  101,X
        UNTIL_ZERO
    PLA
    RTS
 ;------------------



RCV_BYT:                      ; Slave must already be selected, and first bit must already be waiting on MISO.  Output is in A.
    CLK_DN                    ; Prepare for mode-0 receive, and for high clk pulse with INC DEC.
    LDA  #0                   ; We will build up the byte in A, so init it to 0.
    FOR_Y  8, DOWN_TO, 0      ; 8 is the number of bits we will shift in in the loop.
        BIT  VIA3PB           ; MISO is on VIA3PB6, which BIT reflects in the V flag.
        CLC
        IF_V_SET
            SEC               ; Transfer V flag into C flag,
        END_IF
        ROL  A                ; then rotate it into the accum.
        CLK_HI_PULSE          ; Pulse the clock to get the next bit ready, even if it won't get read
    NEXT_Y                    ; until the next RCV_BYT .  Decr the counter and see if we need to repeat.
    RTS                       ; Output is in accum.
 ;------------------

 < now build the routines specific to the SPI ICs you want to use >

=======================================================================================================

; Now the code for simultaneous transmit & receive in the specified SPI mode, as metioned at the top of
; this file.  I added it 12/12/20 as an adaptation of code from Mauizio Neri.  The same structure macros
; are used, from http://wilsonminesco.com/StructureMacros/ .  The make things much more clear; but even
; if you don't want to use them, it will be easy to see what instructions to substitute in.  You will
; probably come up with exactly the same ones the macros lay down.


 COMMENT
    "VIA" is the 6522 or 65C22 Versatile Interface Adapter I/O IC.
    "PA" is its port A.  "DDRA" is the data-direction register for port A's bits.
    MOSI (Master-Out, Slave-In) data is on PA1 (port A, bit 1).  Alter w/ TSB/TRB.
    MISO (Master-In, Slave-Out) data is on PA6 so BIT transfers it to the V flag.
    SCLK (serial clock) is on PA0 so you can raise/lower it with INC/DEC VIA1PA.
    SPI device number is on PA2, 3, and 4.  000 means "leave no device selected."
    A 74__138 would decode the 3 device # bits into 7, plus de-select all for 000.
    The 3 1-byte variables below, or especially SPIOUT and SPIIN, could go in ZP
    if you want maximum performance.  "DFS" in the C32 assembler is short for
    "define storage," ie, dedicate the specified number of bytes as variable space.
    C32 does not use the leading % for binary.  Instead, it uses a trailing B.
 END_COMMENT


SPIMODE:  DFS  1  ; "DFS" in the C32 assembler is like "BLKB" in the 2500AD one.
SPIOUT:   DFS  1  ; The byte to send gets put here, and shifted during sending.
SPIIN:    DFS  1  ; The byte simultaneously being received gets assembled here.


SPI_SCLK: EQU        1B  ; PA0 of VIA1 is  used for SCLK (serial clock).
SPI_MOSI: EQU       10B  ; PA1 of VIA1 is  used for MOSI (master-out, slave-in).
SPI_SSEL: EQU    11100B  ; PA2, 3, & 4 are used for SSEL (slave-select).
SPI_MISO: EQU  1000000B  ; PA6 is used for MISO, to test efficiently with BIT.
                         ; PA5 & PA7 are not used by the SPI.


                                                 ; Init VIA1 for SPI operation.
Init_SPI: STZ  VIA1_PA                           ; Set SCLK, MOSI, & dev-sel low.
          LDA  #{SPI_SCLK | SPI_MOSI | SPI_SSEL} ; Make them outputs.
          STA  VIA1DDRA
          RTS
 ;---------------


 COMMENT
    Sel_SPI_dev below selects an SPI device and prepares for desired comm mode.
    Start with dev # in A, range 1-7.  0 deselects all devices; but it's faster
    use NONE_SELECT which is further up.
    Start with desired SPI communication mode (0, 1, 2, or 3) in X.
    Bad device or mode numbers do not get trapped; however, a bad number means
    the calling routine has other problems anyway.  For a review of SPI modes, see
    https://en.wikipedia.org/wiki/Serial_Peripheral_Interface#Clock_polarity_and_phase
    and the subsequent section.
 END_COMMENT


Sel_SPI_dev:            ; Start with device number in A
        STX  SPIMODE    ; and SPI mode (0, 1, 2, or 3) in X.

        ASL             ; Shift the device number into the correct bit position
        ASL             ; (so it later goes into PA4, 3, and 2),
        TAY             ; and save this bit pattern for the SPI device number.

        TXA
        AND  #10B       ; Bit 1 determines if it is mode 0/1 or mode 2/3
        IF_ZERO         ; If it's mode 0 or 1,
           STZ  VIA1PA  ; make sure the clock is low first, and then
           STY  VIA1PA  ; select the correct device, with clock still low.
           RTS
        END_IF

        LSR  A          ; If it's mode 2 or 3, put that 1 bit in bit 0 and
        STA  VIA1PA     ; store it to the clock output before selecting device.
        TYA             ; Then bring in the SPI address bits and raise the
        ORA  #SPI_SCLK  ; clock bit too to keep it high to start, and
        STA  VIA1PA     ; store it.  PA is set up now.  If dev # was 0, SCLK
        RTS             ; won't matter.
 ;-------------


 COMMENT
    SPI_Xceive below transmits & receives 8 bits of data using chosen SPI mode.
    Start with outgoing data in A.  At the end, A will hold the received data.
 END_COMMENT


Shift_bit_onto_MOSI:  MACRO  ; Made a macro.  A subroutine would ruin performance.
        ASL  SPIOUT          ; Move next output msb into the carry flag.
        IF_CARRY_CLR
           TRB  VIA1_PA      ; If msb was 0, set MOSI low.
        ELSE_
           TSB  VIA1_PA      ; If msb was 1, set MOSI high.
        END_IF
        ENDM
 ;------------------

Rot_MISO_into_SPIIN:  MACRO  ; Made a macro.  A subroutine would ruin performance.
        BIT  VIA1PA          ; The BIT instruction puts MISO (PA6) state in V flag;
        CLC                  ; so transfer that to C flag for rotation into SPIIN.
        IF_V_SET
           SEC
        END_IF
        ROL  SPIIN
        ENDM
 ;------------------

mode_0:  EQU  0
mode_1:  EQU  1
mode_2:  EQU  2
mode_3:  EQU  3


SPI_Xceive:                             ; Start with data to send in A.
        STA  SPIOUT                     ; Store output data, and
        STZ  SPIIN                      ; initialize the input buffer.
        LDY  #8                         ; Set up bit counter.
        LDA  #SPI_MOSI                  ; Put MOSI bit mask in A for TRB/TSB.

        LDX   SPIMODE
        CASE  X_REG

           CASE_OF  mode_0              ; In the case of X saying mode 0,
              FOR_Y  Y_REG, DOWN_TO, 0  ; start into this loop.  Go thru 8x.
                 Shift_bit_onto_MOSI    ; (Shifts SPIOUT to start.)
                 INC  VIA1PA            ; Set SCLK high.
                 Rot_MISO_into_SPIIN    ; Move MISO into the receive buffer.
                 DEC  VIA1PA            ; Set SCLK low.
              NEXT_Y                    ; Decrement our bit counter.
           END_OF


           CASE_OF  mode_1              ; In the case of X saying mode 1:
              FOR_Y  Y_REG, DOWN_TO, 0
                 INC  VIA1PA            ; Set SCLK high.
                 Shift_bit_onto_MOSI    ; (Shifts SPIOUT to start.)
                 DEC  VIA1PA            ; Set SCLK low.
                 Rot_MISO_into_SPIIN    ; Move MISO into receive buffer.
              NEXT_Y
           END_OF


           CASE_OF  mode_2
              FOR_Y  Y_REG, DOWN_TO, 0
                 Shift_bit_onto_MOSI    ; (Shifts SPIOUT to start.)
                 DEC  VIA1PA            ; Set SCLK low.
                 Rot_MISO_into_SPIIN    ; Move MISO into receive buffer.
                 INC  VIA1PA            ; Set SCLK high.
              NEXT_Y
           END_OF


           CASE_OF  mode_3
              FOR_Y  Y_REG, DOWN_TO, 0
                 DEC  VIA1PA            ; Set SCLK low.
                 Shift_bit_onto_MOSI    ; (Shifts SPIOUT to start.)
                 INC  VIA1PA            ; Set SCLK high.
                 Rot_MISO_into_SPIIN    ; Move MISO into receive buffer.
              NEXT_Y
           END_OF
                                        ; You could handle invalid SPI modes
                                        ; here before END_CASE if desired.
        END_CASE

        LDA  SPIIN                      ; Returns the received data in Accum.
        RTS
 ;------------------



last updated: Jan 1, 2022


