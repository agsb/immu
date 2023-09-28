
; ($7FFB, $7FFA):	NMI RAM vector
; ($7FFF, $7FFE):       IRQ RAM vector
; (User program may not set a new RESET vector, or we could load
; an unrecoverable program into SRAM if battery backed, which would
; kill the system until the RAM was removed!)
;
;
; Macros for converting 16-bit values to high and low bytes
#define hi(x)  (x >> 8)
#define lo(x)  (x & $FF)
;
; 6551 ACIA equates for serial I/O
;
#define ACIA_BASE $F000	        ; This is where the 6551 ACIA starts
#define SDR  	ACIA_BASE       ; RX'ed bytes read, TX bytes written, here
#define SSR     ACIA_BASE+1     ; Serial data status register. A write here
                                ; causes a programmed reset.
#define SCMD    ACIA_BASE+2     ; Serial command reg. ()
#define SCTL    ACIA_BASE+3     ; Serial control reg. ()
; Quick n'dirty assignments instead of proper definitions of each parameter
; "ORed" together to build the desired flexible configuration.  We're going
; to run 19200 baud, no parity, 8 data bits, 1 stop bit.  Period.  For now.
;
#define SCTL_V  00011111b       ; 1 stop, 8 bits, 19200 baud
#define SCMD_V  00001011b       ; No parity, no echo, no tx or rx IRQ, DTR*
#define TX_RDY  00010000b       ; AND mask for transmitter ready
#define RX_RDY  00001000b       ; AND mask for receiver buffer full
;
; Zero-page storage
#define DPL             $00     ; data pointer (two bytes)
#define DPH             $01     ; high of data pointer
#define RECLEN          $02     ; record length in bytes
#define START_LO        $03
#define START_HI        $04
#define RECTYPE         $05
#define CHKSUM          $06     ; record checksum accumulator
#define DLFAIL          $07     ; flag for download failure
#define TEMP            $08     ; save hex value

; "Shadow" RAM vectors (note each is $8000 below the actual ROM vector)
#define	NMIVEC		$7FFA	; write actual NMI vector here
#define IRQVEC          $7FFE   ; write IRQ vector here

#define	ENTRY_POINT	$0200	; where the RAM program MUST have its first instruction

org $F800
;
START   sei                     ; disable interrupts
        cld                     ; binary mode arithmetic
        ldx     #$FF            ; Set up the stack pointer
        txs                     ;       "
        lda     #hi(START)      ; Initialiaze the interrupt vectors
        sta     NMIVEC+1        ; User program at ENTRY_POINT may change
        sta     IRQVEC+1	; these vectors.  Just do change before enabling
        lda     #lo(START)	; the interrupts, or you'll end up back in the d/l monitor.
        sta     NMIVEC
        sta     IRQVEC
        jsr     INITSER         ; Set up baud rate, parity, etc.
        ; Download Intel hex.  The program you download MUST have its entry
        ; instruction (even if only a jump to somewhere else) at ENTRY_POINT.
HEXDNLD lda     #0
        sta     DLFAIL          ;Start by assuming no D/L failure
        jsr     PUTSTRI
        .byte   13,10,13,10
        .byte   "Send 6502 code in"
        .byte   " Intel Hex format"
        .byte  " at 19200,n,8,1 ->"
        .byte   13,10
	.byte	0		; Null-terminate unless you prefer to crash.
HDWRECS jsr     GETSER          ; Wait for start of record mark ':'
        cmp     #':'
        bne     HDWRECS         ; not found yet
        ; Start of record marker has been found
        jsr     GETHEX          ; Get the record length
        sta     RECLEN          ; save it
        sta     CHKSUM          ; and save first byte of checksum
        jsr     GETHEX          ; Get the high part of start address
        sta     START_HI
        clc
        adc     CHKSUM          ; Add in the checksum
        sta     CHKSUM          ;
        jsr     GETHEX          ; Get the low part of the start address
        sta     START_LO
        clc
        adc     CHKSUM
        sta     CHKSUM
        jsr     GETHEX          ; Get the record type
        sta     RECTYPE         ; & save it
        clc
        adc     CHKSUM
        sta     CHKSUM
        lda     RECTYPE
        bne     HDER1           ; end-of-record
        ldx     RECLEN          ; number of data bytes to write to memory
        ldy     #0              ; start offset at 0
HDLP1   jsr     GETHEX          ; Get the first/next/last data byte
        sta     (START_LO),y    ; Save it to RAM
        clc
        adc     CHKSUM
        sta     CHKSUM          ;
        iny                     ; update data pointer
        dex                     ; decrement count
        bne     HDLP1
        jsr     GETHEX          ; get the checksum
        clc
        adc     CHKSUM
        bne     HDDLF1          ; If failed, report it
        ; Another successful record has been processed
        lda     #'#'            ; Character indicating record OK = '#'
        sta     SDR             ; write it out but don't wait for output
        jmp     HDWRECS         ; get next record
HDDLF1  lda     #'F'            ; Character indicating record failure = 'F'
        sta     DLFAIL          ; download failed if non-zero
        sta     SDR             ; write it to transmit buffer register
        jmp     HDWRECS         ; wait for next record start
HDER1   cmp     #1              ; Check for end-of-record type
        beq     HDER2
        jsr     PUTSTRI         ; Warn user of unknown record type
        .byte   13,10,13,10
        .byte   "Unknown record type $",
	.byte	0		; null-terminate unless you prefer to crash!
        lda     RECTYPE         ; Get it
	sta	DLFAIL		; non-zero --> download has failed
        jsr     PUTHEX          ; print it
	lda     #13		; but we'll let it finish so as not to
        jsr     PUTSER		; falsely start a new d/l from existing
        lda     #10		; file that may still be coming in for
        jsr     PUTSER		; quite some time yet.
	jmp	HDWRECS
	; We've reached the end-of-record record
HDER2   jsr     GETHEX          ; get the checksum
        clc
        adc     CHKSUM          ; Add previous checksum accumulator value
        beq     HDER3           ; checksum = 0 means we're OK!
        jsr     PUTSTRI         ; Warn user of bad checksum
        .byte   13,10,13,10
        .byte   "Bad record checksum!",13,10
        .byte   0		; Null-terminate or 6502 go bye-bye
        jmp     START
HDER3   lda     DLFAIL
        beq     HDEROK
        ;A download failure has occurred
        jsr     PUTSTRI
        .byte   13,10,13,10
        .byte   "Download Failed",13,10
        .byte   "Aborting!",13,10
	.byte	0		; null-terminate every string yada yada.
        jmp     START
HDEROK  jsr     PUTSTRI
        .byte   13,10,13,10
        .byte   "Download Successful!",13,10
        .byte   "Jumping to location $"
	.byte	0			; by now, I figure you know what this is for. :)
        lda	#hi(ENTRY_POINT)	; Print the entry point in hex
        jsr	PUTHEX
        lda	#lo(ENTRY_POINT)
	jsr	PUTHEX
        jsr	PUTSTRI
        .byte   13,10
        .byte   0		; stop lemming-like march of the program ctr. thru data
        jmp     ENTRY_POINT	; jump to canonical entry point

;
; Set up baud rate, parity, stop bits, interrupt control, etc. for
; the serial port.
INITSER lda     #SCTL_V 	; Set baud rate 'n stuff
        sta     SCTL
        lda     #SCMD_V 	; set parity, interrupt disable, n'stuff
        sta     SCMD
        rts

;
;
; SerRdy : Return
SERRDY  lda     SSR     	; look at serial status
        and     #RX_RDY 	; strip off "character waiting" bit
        rts             	; if zero, nothing waiting.
; Warning: this routine busy-waits until a character is ready.
; If you don't want to wait, call SERRDY first, and then only
; call GETSER once a character is waiting.
GETSER  lda     SSR    		; look at serial status
        and     #RX_RDY 	; see if anything is ready
        beq     GETSER  	; busy-wait until character comes in!
        lda     SDR     	; get the character
        rts
; Busy wait

GETHEX  jsr     GETSER
        jsr     MKNIBL  	; Convert to 0..F numeric
        asl     a
        asl     a
        asl     a
        asl     a       	; This is the upper nibble
        and     #$F0
        sta     TEMP
        jsr     GETSER
        jsr     MKNIBL
        ora     TEMP
        rts             	; return with the nibble received

; Convert the ASCII nibble to numeric value from 0-F:
MKNIBL  cmp     #'9'+1  	; See if it's 0-9 or 'A'..'F' (no lowercase yet)
        bcc     MKNNH   	; If we borrowed, we lost the carry so 0..9
        sbc     #7+1    	; Subtract off extra 7 (sbc subtracts off one less)
        ; If we fall through, carry is set unlike direct entry at MKNNH
MKNNH   sbc     #'0'-1  	; subtract off '0' (if carry clear coming in)
        and     #$0F    	; no upper nibble no matter what
        rts             	; and return the nibble

; Put byte in A as hexydecascii
PUTHEX  pha             	;
        lsr a
        lsr a
        lsr a
        lsr a
        jsr     PRNIBL
        pla
PRNIBL  and     #$0F    	; strip off the low nibble
        cmp     #$0A
        bcc     NOTHEX  	; if it's 0-9, add '0' else also add 7
        adc     #6      	; Add 7 (6+carry=1), result will be carry clear
NOTHEX  adc     #'0'    	; If carry clear, we're 0-9
; Write the character in A as ASCII:
PUTSER  sta     SDR     	; write to transmit register
WRS1    lda     SSR     	; get status
        and     #TX_RDY 	; see if transmitter is busy
        beq     WRS1    	; if it is, wait
        rts
;Put the string following in-line until a NULL out to the console
PUTSTRI pla			; Get the low part of "return" address (data start address)
        sta     DPL
        pla
        sta     DPH             ; Get the high part of "return" address
                                ; (data start address)
        ; Note: actually we're pointing one short
PSINB   ldy     #1
        lda     (DPL),y         ; Get the next string character
        inc     DPL             ; update the pointer
        bne     PSICHO          ; if not, we're pointing to next character
        inc     DPH             ; account for page crossing
PSICHO  ora     #0              ; Set flags according to contents of Accumulator
        beq     PSIX1           ; don't print the final NULL
        jsr     PUTSER          ; write it out
        jmp     PSINB           ; back around
PSIX1   inc     DPL             ;
        bne     PSIX2           ;
        inc     DPH             ; account for page crossing
PSIX2   jmp     (DPL)           ; return to byte following final NULL
;
; User "shadow" vectors:
GOIRQ	jmp	(IRQVEC)
GONMI	jmp	(NMIVEC)
GORST	jmp	START		; Allowing user program to change this is a mistake

.org $FFFA
;  start at $FFFA
NMIENT  .word     GONMI
RSTENT  .word     GORST
IRQENT  .word     GOIRQ
.end				; finally.  das Ende.

