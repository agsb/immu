;
; 09/2023 agsb@ adapted from http://wilsonminesco.com/6502primer/GENRLI2C.ASM

; This file has six sets of source code (the 6th one having been added 7/27/22):
; A. 65c02 source code for running the I2C interface as shown at
;    http://wilsonminesco.com/6502primer/potpourri.html#BITBANG_I2C in the 6502
;    primer's "potpourri" page.  I ran it with the actual circuit just enough
;    to have a degree of confidence the I'm not steering you wrong.
; B. a section on changes to make if you use different bit numbers
; C. my working Forth source code for using the 24256 32Kx8 I2C EEPROM.  Even if
;    you don't know Forth, much of it should be pretty clear as to what order
;    things need to happen in to interface to this 8-pin serial EEPROM.
;    It is profusely commented.
; D. my working Forth code for operating the MAX520 quad D/A converter.
; E. my working PIC code for running a tiny 24c00 EEPROM that was put as a
;    separate die in the PIC12CE673 we used for a product.
; F. my working PIC16 code for running a 24256 32Kx8 EEPROM that was part of
;    a semi-medical product I developed for work.  Even if you're not familiar
;    with PIC16 assembly language, the major use of macros with friendly names
;    should make it pretty clear the sequence of things that have to happen
;    to operate the 24256.

; Obviously you will need to separate out the needed parts for the applicable
; assembler or compiler.


COMMENT: MACRO          ; COMMENT and END_COMMENT here relieve us from having to
         IF 0           ; contend with so many semicolons in places where we
         ENDM           ; have many lines of comments together.  Since the IF is
 ;-------------------   ; looking for an ELSE or ENDI (either cap.s or lower
END_COMMENT: MACRO      ; case), just be sure none of the lines commented-out
        ENDI            ; start with one of these words that could cause
        ENDM            ; problems by fooling it.  If there is, that line will
 ;-------------------   ; still need a semicolon.  Also, if a line starts with a
                        ; macro name which is followed by illegal parameters for
                        ; that macro (as in a discussion of it), you will still
                        ; need the semicolon.

 COMMENT
   First:  General I2C material for 65c02, with bit numbers for the
   I2C-interfacing schematic in the 6502 primer's "potpourri" page at
   http://WilsonMinesCo.com/6502primer/potpourri.html

   Power control is on the VIA's PB7.  Holding the port bit high turns the I2C
   power off.  The bit can be used for other things as long as it is not held
   high for more that about 25ms when you want the I2C power to remain on.  This
   lets you simultaneously use PB7 for a beeper or a signal source for something
   else_ at the same time.  (The 25ms here is definitely not exact!)  This does
   mean the other function will have to store the PB7 value and put it back when
   it's done.

   The I2C clock line is on PA0, so you can form a clock pulse with only two
   instructions, INC & DEC.

   The I2C data line is on PA7 so that testing it takes fewer instructions than
   having to AND-out other bits or load the accumulator.

   In I2C, devices (and the controller) can pull the lines down, but not up.
   In most cases it's ok for the controller to pull the clock line up as well as
   down, but here we'll go with pull down only, and use the passive pull-up
   resistors for both data and clock.  The way to do that with the 6522 VIA is
   to put a "0" in the output register bit of interest, then set the
   corresponding bit in the data-direction register (DDRA in this case) to make
   the line an output and pull it down, or clear the DDRA bit to make the line
   an input and let it float up by the pull-up resistor.
 END_COMMENT


 HOF  "INT8"                    ; This tells C32 to output 8-bit Intel Hex.
 CPU  "6502.TBL"                ; Tell the assembler which processor.  (In C32,
                                ;            6502 includes 65c02 instructions.)

 ORG $000A                      ; Just one variable.  Put it wherever you like.
I2C_TEMP:  DFS  1               ; DFS in C32 is "DeFine Storage" for variables,
                                ;             and this reserves one byte for it.

VIA_BASE_ADR:  EQU  $4800       ; (Base address of the 6522 VIA.)
PB:     EQU  VIA_BASE_ADR + 0   ; Addresses of 16 registers in 6522.
PA:     EQU  VIA_BASE_ADR + 1   ; (We really only need the first four for this.)
DDRB:   EQU  VIA_BASE_ADR + 2
DDRA:   EQU  VIA_BASE_ADR + 3
T1CL:   EQU  VIA_BASE_ADR + 4
T1CH:   EQU  VIA_BASE_ADR + 5
T1LL:   EQU  VIA_BASE_ADR + 6
T1LH:   EQU  VIA_BASE_ADR + 7
T2CL:   EQU  VIA_BASE_ADR + 8
T2CH:   EQU  VIA_BASE_ADR + 9
SR:     EQU  VIA_BASE_ADR + $A
ACR:    EQU  VIA_BASE_ADR + $B
PCR:    EQU  VIA_BASE_ADR + $C
IFR:    EQU  VIA_BASE_ADR + $D
IER:    EQU  VIA_BASE_ADR + $E
PANOHS: EQU  VIA_BASE_ADR + $F


 ORG $3000    ; I stuck it at $3000.  You will probably want to change that.


I2C_DATA_UP: MACRO
             LDA   #10000000B   ; Two instructions here.  Clear bit 7 of the DDR
             TRB   DDRA         ; to make PA7 an input and let it float up.
             ENDM
 ;-----------------------

I2C_DATA_DN: MACRO
             LDA   #10000000B   ; Two instructions here.  Set bit 7 of the DDR
             TSB   DDRA         ; to make PA7 an output and pull it down since
             ENDM               ; bit 7 of the output register is a 0.
 ;-----------------------

I2C_CLK_UP:  MACRO              ; (as above)
             LDA   #1
             TRB   DDRA
             ENDM
 ;-----------------------

I2C_CLK_DN:  MACRO              ; (as above)
             LDA   #1
             TSB   DDRA
             ENDM
 ;-----------------------

I2C_START:   I2C_DATA_UP
             I2C_CLK_UP
             I2C_DATA_DN
 ist1:       INC   DDRA         ; Clk down.  We now know the bit val, so just INC.
             TRB   DDRA         ; Data up, using accum val left from I2C_DATA_DN above.
             RTS
 ;-----------------------

I2C_STOP:    I2C_DATA_DN
             I2C_CLK_UP
             I2C_DATA_UP
             BRA   ist1
 ;-----------------------

I2C_ACK:     I2C_DATA_DN        ; Acknowledge.  The ACK bit in I2C is the 9th bit of a "byte".
 ia1:        I2C_CLK_UP         ;               and acknowledging consists of pulling it down.
             INC   DDRA         ; Clk down.  We know the bit val, so just INC.
             I2C_DATA_UP
             RTS
 ;-----------------------

I2C_NAK:     I2C_DATA_UP        ; Not acknowledge.
             BRA   ia1
 ;-----------------------

I2C_ACK?:    I2C_DATA_UP        ; At end, N=0 means ACK.  N=1 means NAK.
             I2C_CLK_UP
             BIT   PA           ; Bit 7 (the data line) gets put in the N flag.
             TSB   DDRA         ; Clk down.  Accum still has 1 from I2C_CLK_UP.  Take advantage.
             RTS
 ;-----------------------

I2C_PWR_ON:  LDA   #10000000B   ; Clear bit 7 of port B.  It must first be made an output by doing INIT_I2C.
             TRB   PB
             RTS
 ;-----------------------

I2C_PWR_OFF:                    ; (Basically the same as INIT_I2C below.)
INIT_I2C:                       ; Set up the port bit directions and values.  Leaves power off, clk & data low.
        LDA     #10000000B
        TSB     PB              ; Make PB7 put out a high level (I2C power off) when made an output,
        TSB     DDRB            ; then make PB7 an output.

        INC     A               ; Put 10000001B in A for data and clock lines on port A.
        TSB     DDRA            ; Make PA0 and PA7 outputs to hold clock and data low while power is off,
        TRB     PA              ; and make the output value to be 0 for the same.
        RTS                     ; You might want to leave a delay to let the power die out so devices are really
 ;------------------            ;    cleared before turning it back on.  Then you shouldn't need CLR_I2C below.

CLR_I2C:                        ; This clears any unwanted transaction that might be in progress, by giving
        JSR     I2C_STOP        ;    enough clock pulses to finish a byte and not acknowledging it.
        JSR     I2C_START
        I2C_DATA_UP             ; Keep data line released so we don't ACK any byte sent by a device.
        LDX     #9              ; Loop 9x to send 9 clock pulses to finish any byte a device might send.
 ci2c:     DEC  DDRA            ; Like I2C_CLK_UP since we know I2C_START left clock down (DDRA bit 0 high).
           INC  DDRA            ; Like I2C_CLK_DN since we know the state from the above instruction.
           DEX
        BNE     ci2c
        JSR     I2C_START
        JMP     I2C_STOP        ; (JSR, RTS)
 ;------------------

SEND_I2C_BYTE:                  ; Start with byte in A, and clock low.  Ends with I2C_ACK?.
        STA     I2C_TEMP        ; Store the byte in a variable so we can use A with TSB & TRB for data line.
        LDA     #10000000B      ; Init A for mask for TRB & TSB below.  A does not get disturbed below.
        LDX     #8              ; We will do 8 bits.
 sIb2:     TRB  DDRA            ; Release data line.  This is like I2C_DATA_UP but saves 1 instruction.
           ASL  I2C_TEMP        ; Get next bit to send and put it in the C flag.
           BCS  sIb1
              TSB DDRA          ; If the bit was 0, pull data line down by making it an output.
 sIb1:     DEC  DDRA            ; Do a high pulse on the clock line.  Remember there's a 0 in the output
           INC  DDRA            ; register bit, and DEC'ing DDRA makes that bit an input, so it can float up.
           DEX                  ;    IOW, it's backwards from what it seems.
        BNE     sIb2
        JMP     I2C_ACK?        ; (JSR, RTS)
 ;------------------

RCV_I2C_BYTE:                   ; Start with clock low.  Ends with byte in I2C_TEMP.  Do ACK bit separately.
        I2C_DATA_UP             ; Make sure we're not holding the data line down.  Be ready to input data.
        LDX     #8              ; We will do 8 bits.  There's no need to init I2C_TEMP.
 rIb1:     DEC  DDRA            ; Set clock line high.
           ASL  I2C_TEMP        ; Get the forming byte's next bit position ready to accept the bit.
           BIT  PA              ; Read the data line value into N flag.
           BPL  rIb2            ; If the data line was high,
              INC  I2C_TEMP     ; increment the 1's place to a 1 in the forming byte.  (ASL made bit 0 = 0.)
 rIb2:     INC  DDRA            ; Put clock line back low.
           DEX
        BNE     rIb1            ; Go back for next bit if there is one.
        RTS
 ;------------------

 END
