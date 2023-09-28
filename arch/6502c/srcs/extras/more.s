;------------------------------------------------------------------------------
.END
;
;==============================================================================   
; some code to study
;------------------------------------------------------------------------------


http://forum.6502.org/viewtopic.php?f=9&t=7024

;------------------------------------------------------------------------------
: /MOD          ( n1 n2 -- rem quot )   \       SF39-40  F83  ANS
   >R  S>D  R> M/MOD    ;

: U/MOD         ( u1 u2 -- rem quot )   \ My own.  Faster than /MOD if you don't
   0  SWAP  UM/MOD      ;               \ need to deal with negative numbers.

: /             ( n1 n2 -- quot )       \       SF32  F83  ANS
   /MOD  NIP            ;

: U/            ( u1 u2 -- quot )       \ My own.  Faster than / if you don't
   U/MOD NIP            ;               \ need to deal with negative numbers.

: MOD           ( n1 n2 -- rem )        \       SF39-40  F83  ANS
   /MOD  DROP           ;

: UMOD          ( u1 u2 -- rem )        \ My own.  Faster than MOD if you don't
   U/MOD DROP           ;               \ need to deal with negative numbers.

;------------------------------------------------------------------------------

: UD/MOD        ( d n -- rem dquot )    \ Used in #                       FNM287
   >R  0  R@       \ ^ input_lo_cell  input_hi_cell  0  n  \ Put base on R stack
   UM/MOD          \ ( ud base -- rem quot )  ^ in_lo_cell  rem  quot
   R>  SWAP  >R    \ ^ in_lo_cell  rem  base           \ Put 1st quot on R stack
   UM/MOD          \ ( ud base -- rem quot )
   R>           ;  \ ^ rem quot2 quot1

;------------------------------------------------------------------------------

: HOLD          ( ASCII -- )            \               SF151-156  FIG  ANS_CORE
   HLD  DECR
   HLD  @  C!                   ;

: >DIGIT                ( n -- ASCII_char ) ( b -- ASCII_char ) \ used in #
   DUP 9 >              \ Greater than 9?
   IF 7 + THEN          \ If so, add 7;  then
   30 +         ;       \ add 30.


: #             ( d1 -- d2 )            \               SF152-154  FIG  ANS_CORE
   BASE @  UD/MOD
   ROT >DIGIT HOLD              ;

: ##  #  #      ( d1 -- d2 )    ;       \ No header. Used internally to save mem

: #>            ( d -- addr len )       \               SF151-156  FIG  ANS_CORE
   2DROP
   PAD 1- HLD @ -               ;

: SIGN          ( n -- )                \               SF154-155  FIG  ANS_CORE
   0<           IF
   ASCII - HOLD ELSE
   DROP         THEN            ;

: #S            ( d1 -- d0 )            \             SF151-154,  FIG,  ANS_CORE
   BEGIN   # 2DUP D0=   UNTIL   ;

: D.R           ( d width -- )          \               SF157,  FIG,  ANS_DOUBLE
   >R DUP >R DABS <# #S R> SIGN #>
   R> OVER - SPACES TYPE        ;

: D.            ( d -- )                \                 SF150,155,  ANS_DOUBLE
   0  D.R  SPACE                ;

: .             ( n -- )                \            SF20,21,26,  FIG,  ANS_CORE
   S>D  D.                      ;

: ?             ( addr -- )             \                              ANS_TOOLS
   @ .                          ;

: U.            ( u -- )                \                       SF147,  ANS_CORE
   0  D.                        ;

: U.R           ( u width -- )          \                   SF148,  ANS_CORE_EXT
   0  SWAP  D.R                 ;

: .R            ( n width -- )          \         SF123,131,  FIG,  ANS_CORE_EXT
   >R  S>D  R>  D.R             ;

;------------------------------------------------------------------------------
;
http://forum.6502.org/viewtopic.php?f=9&t=6945&start=15
IamRob 	
Post subject: Re: Why is PAD 68 bytes above the DP?
PostPosted: Tue Jan 11, 2022 3:32 am 
Offline

Joined: Sun Apr 26, 2020 3:08 am
Posts: 320 	
I wrote a better description for WORD for FigForth. Instead of it clearing 34 spaces after HERE every time, it just stores one space after the enclosing the word and copying it to HERE, whether it be a definition word or a number

Change from this:
Code:
* : WORD ( delimiterchar -- ) BLK @ IF BLK @ BLOCK ELSE TIB @ THEN IN @ +
SWAP ENCLOSE HERE CLIT [ 22 C, ] BLANKS IN +! OVER - >R R HERE C! + HERE 1+ R> CMOVE ;
to this:
Code:
: stream ( -- adr ) blk @ ?dup if block else tib @ then in @ + ;
: word stream swap enclose >R R > if R> ddrop ddrop 0 here ! else R in +! bl R> HERE + 1+ c! over - HERE C! + HERE count cmove then ;
This one also does some error checking if no word or number is copied to HERE but stores a zero instead. INTERPRET could then read the zero at HERE to see if there is a valid word or number at HERE and exit cleanly if not.


;---------------------------------------------------------------------
; zzzz not finished
;
; next: 
;   ldy irqnot
;   beq runISR
;   ...
;   bcs inc_hi
;   jmp wrk - 1
;
;inc_hi:
;   inc nos + 1
;   jmp wrk - 1
;
HEADER "IRQOK", "IRQOK", F_LEAP, LEAF
    cli
    ; continue
    jmp unnest

HEADER "NOIRQ", "NOIRQ", F_LEAP, LEAF
    sei
    ; continue
    jmp unnest

HEADER "SYSRTI", "SYSRTI", F_LEAP, LEAF
    sei
    lda irqnot
    beq noi
    cli
noi:
    ; continue
    jmp unnest

HEADER "IRQOK?", "IRQOKQ", F_LEAP, LEAF
    php
    pla
    and #4
    beq irqf
    jmp FFALSE
irqf: 
    jmp FTRUE

runISR:
    inc irqnot
    jmp (irqvec)

irqroute:
    jmp (irqvec)

setirq:
    sta a_save
    ; clear byte irq flag
    lda #0
    sta irqnot
    ; set bit 4 flag
    pla
    ora #4
    pha
    lda a_save
    rti


;------------------------------------------------------------------------------
;
; http://forum.6502.org/viewtopic.php?f=4&t=7466
;
; floobydust;  Post subject: Re: Don't write to ROM 
; Unread postPosted: Sun Jan 22, 2023 11:31 am
;
; Byte write code for EEPROM.
; Note: AT28BV256 requires an unlock sequence for all write operations.
;  This is different from earlier Atmel EEPROMs (i.e., AT28C256). The
;  sequence must be sent first to unlock the device, then data can be
;  sent for programming. Note that byte writes can be 1 to 64 bytes.
;  The EEPROM is defined in constants for the Offset of the EEPROM in
;  the hardware memory map.
;
BYTE_WRS        SEI                     ;Disable interrupts
;
                LDA     #$AA            ;Get code $AA
                STA     EEPROM+$5555    ;Send to EEPROM
                LDA     #$55            ;Get code $55
                STA     EEPROM+$2AAA    ;Send to EEPROM
                LDA     #$A0            ;Get code $A0
                STA     EEPROM+$5555    ;Send to EEPROM
;
                LDA     (SRCL)          ;Get source byte
                STA     (TGTL)          ;Write to target byte
                LDA     (TGTL)          ;Read target byte (EEPROM)
                AND     #%01000000      ;Mask off bit 6 - toggle bit
BYTE_WLP        STA     TEMP3           ;Store in Temp location
                LDA     (TGTL)          ;Read target byte again (EEPROM)
                AND     #%01000000      ;Mask off bit 6 - toggle bit
                CMP     TEMP3           ;Compare to last read (toggles if write mode)
                BNE     BYTE_WLP        ;Branch back if not done
                CLI                     ;Re-enable interrupts
BYTE_WRE        RTS                     ;Return to caller
;
;------------------------------------------------------------------------------
;
; tipical loop for 6522
;
L1   <fetch the value to be written and put it in the X register>
    LDA #$02    ; THE MASK
L2    
    BIT IFR     ;POLLING THE INTERRUPT FLAG REGISTER
    BEQ L2
    STX PORT    ;WRITE TO THE I/O REGISTER
    JMP L1

;------------------------------------------------------------------------------
;   check address lines a14 to a0
;   http://6502.org/source/general/address_test.html
;
;   to check ram, use $55 $AA in every address
;
;------------------------------------------------------------------------------

;==============================================================================
;------------------------------------------------------------------------------
;https://codebase64.org/doku.php?id=base:16bit_multiplication_32-bit_product

;16-bit multiply with 32-bit result 
;took from 6502.org
 
multiplier	= $f7 
multiplicand	= $f9 
product		= $fb 
 
mult16: 		
        lda	#$00
		sta	product+2	; clear upper bits of product
		sta	product+3 
		ldx	#$10		; set binary count to 16 
shift_r:
        lsr	multiplier+1	; divide multiplier by 2 
		ror	multiplier
		bcc	rotate_r 
		lda	product+2	; get upper half of product and add multiplicand
		clc
		adc	multiplicand
		sta	product+2
		lda	product+3 
		adc	multiplicand+1
rotate_r:
        ror			; rotate partial product 
		sta	product+3 
		ror	product+2
		ror	product+1 
		ror	product 
		dex
		bne	shift_r 
		rts


;---------------------------------------------------------------------
;16-bit division with 32-bit result 
;took from 6502.org

divisor = $58     ;$59 used for hi-byte
dividend = $fb	  ;$fc used for hi-byte
remainder = $fd	  ;$fe used for hi-byte
result = dividend ;save memory by reusing divident to store the result

divide:	
	lda #0	        ;preset remainder to 0
	sta remainder
	sta remainder+1
	ldx #16	        ;repeat for each bit: ...

divloop:
	asl dividend	;dividend lb & hb*2, msb -> Carry
	rol dividend+1	
	rol remainder	;remainder lb & hb * 2 + msb from carry
	rol remainder+1
	lda remainder
	sec
	sbc divisor	;substract divisor to see if it fits in
	tay	        ;lb result -> Y, for we may need it later
	lda remainder+1
	sbc divisor+1
	bcc skip	;if carry=0 then divisor didn't fit in yet

	sta remainder+1	;else save substraction result as new remainder,
	sty remainder	
	inc result	;and INCrement result cause divisor fit in 1 times

skip:
	dex
	bne divloop	
	rts

;==============================================================================

; @Lee Davison
;
;   1.  clear carry, and set N Z
;
;   rol a
;   eor #$1
;   ror a
;
;   2.  check 0 < n < m < $FF
; 
;   sec
;   sbc #n            ; 
;   sbc #m - n + 1    ;
;   bcc   n < A < m 
;
;   3. nibble to ASCII
;
;   and #$0F
;   cmp #$0A
;   bcc @no
;   adc #6
;@no:
;   adc #'0'
;

