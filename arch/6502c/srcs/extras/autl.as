;AUTL.AS -- 08/10/96,  version 1.0.0
;Autoloader for DIY 6502 board.
;all code original material by author
;Copyright (c) 1996 Douglas Beattie Jr.

; ACIA is hooked to INT
; VIA is hooked to NMI

NMIVECT EQU     $0067           ;RAM vector for NMI
DATA    EQU     $80             ;base of variable table
FIFOBUF EQU     $0200           ;receiver buffer
VIA     EQU     $C000           ;address of 6522 VIA
ACIA    EQU     $D000           ;address of 6551 ACIA
ROMCODE EQU     -2048           ;$F800=start of 2K ROM

;
; 6522 VIA definitions
;
        ORG     VIA
ORB     .DS     1               ;Output Register B
IRB     EQU     ORB             ;Input Register B
ORA     .DS     1               ;Output Register A
IRA     EQU     ORA             ;Input Register A
DDRB    .DS     1               ;Data Direction Register B
DDRA    .DS     1               ;Data Direction Register A
T1CL    .DS     1               ;read:  T1 counter, low-order
                                ;write: T1 latches, low-order
T1CH    .DS     1               ;T1 counter, high-order
T1LL    .DS     1               ;T1 latches, low-order
T1LH    .DS     1               ;T1 latches, high-order
T2CL    .DS     1               ;read:  T2 counter, low-order
                                ;write: T2 latches, low-order
T2CH    .DS     1               ;T2 counter, high-order
SR      .DS     1               ;Shift Register
ACR     .DS     1               ;Auxiliary Control Register
PCR     .DS     1               ;Peripheral Control Register
IFR     .DS     1               ;Interrupt Flag Register
IER     .DS     1               ;Interrupt Enable Register




;
; 6551 ACIA definitions
;
        ORG     ACIA
ATXM    .DS     1               ;Transmitter Register (write only)
ARCX    EQU     ATXM            ;Receiver Register (read only)
ASTS    .DS     1               ;Status Register (read only)
ARES    EQU     ASTS            ;Soft Reset  (write only)
ACMD    .DS     1               ;Command Register
ACTL    .DS     1               ;Control Register


;
; page zero variable declarations
;
        ORG     DATA
INBFPTR .DS     2               ;pointer to FIFO input buffer
INHEAD  .DS     1               ;byte offset to head of buffer
INTAIL  .DS     1               ;byte offset to tail of buffer

FLGREG  .DS     1
ECHO    EQU     2               ;flag if recx echo-back is on.

NMIVCT  .DS     2               ;Non-Maskable Interrupt RAM vector
;
RECTYPE .DS     1               ;record type and boolean condition for E-o-f
RECLEN  .DS     1               ;record length
DTX1    .DS     1               ;Last-byte-in-file flag for POLBYT
DTXX    .DS     1               ;temporary momentary
HXBYT   .DS     1               ;temporary storage for HXGET routine
EXECABL .DS     1               ;flag=non-zero if executable
;
STPTR1  .DS     2               ;Pointer to a software stack
STOFST  .DS     1               ;indexed offset into the stack
;
CKSDTUM .DS     1               ;running checksum datum
BYTCTR  .DS     1               ;object bytes input counter
LDADDR  .DS     1               ;LSB of object load address
        .DS     1               ;MSB of object load address
;


        ORG     FIFOBUF         ;currently is $0200
INBUFR  .DS     128             ;receiver input buffer

        ORG     $7E00
;
SWSTK1  .DS     256             ;software stack no. 1
SWSTK2  .DS     256



        ORG     ROMCODE


;*********************************************
;****  I/O ROUTINES
;*********************************************

;
; receive a byte into the system (console input)
; place into FIFO input buffer
;
RCXBYT  AND     #$7F            ;mask high bit out
        PHA                     ;save for a moment
        LDY     INTAIL
        INY
        TYA
        AND     #$7F            ;input buffer is 128 bytes wraparound
        TAY                     ; use adjusted index value
        PLA                     ;recover datum
        STA     (INBFPTR),Y     ;  and put into buffer
        STY     INTAIL          ;update buffer pointer
;        RTS                     ;***FOR NOW, NO ECHO FUNCTION
        JMP     TXMBYT
; if ECHO follow through and re-transmit it!!
        LDA     #ECHO
        BIT     FLGREG
        BNE     TXMBYT
        RTS

;TXMBYT sends a byte OUT from the system (send to the console)
;Since the system is not driven by a RTC interrupt, no
;  output FIFO buffer is utilized.
;When system software calls this routine, the byte is
;  transmitted immediately (or fails on time-out)
;
TXMBYT  PHA
        LDY     #00
TXMBY1  DEY                     ;short delay
        BNE     TXMBY1
        LDY     #50
TXMBY2  LDA     ASTS
        AND     #$10            ;txm dta reg empty?
        BNE     TXOUP           ;0=not empty
        DEY
        BNE     TXMBY2
        BEQ     TXMFL           ;fail
TXOUP   PLA
        STA     ATXM            ;send to transmitter
        LDA     #$00            ;set Z-flg=okay
        RTS
TXMFL   LDA     #ERRTXM
        JSR     ERROR
        ORA     #1              ;set NZ
        PLA                     ;return the character
        RTS                     ;  and NZ=error

;*********************************************
;****  HARDWARE INITIALIZATION ROUTINES
;*********************************************
;
;         Initialize the 6522 VIA
;
INIT22  LDA     #$00            ;set all bits as input
        STA     DDRB
        LDA     #$80            ;Handshake OUTPUT mode
        STA     PCR             ;  with CB1 active low
        LDA     #$90            ;Use CB1 as an interrupt
        STA     IER
        LDA     #255            ;arbitrary value
        STA     ORB             ;Important - reset BUSY
        RTS
;
; initialize UART (6551 ACIA)
;
UINIT   STA     ARES            ;soft reset
        LDA     #$89            ;set specific modes and functions
        STA     ACMD
;       LDA     #$1A            ;8-N-1, 2400 baud
        LDA     #$1E            ;8-N-1, 9600 baud
        STA     ACTL
        CLI                     ;enable CPU interrupts
        RTS
;
;          Initialization (COLD BOOT).
INIT
;
;         initialize the software stack
;
        LDA     #0
        STA     STOFST          ;init stack pointer to zero
        LDA     #SWSTK1         ; & $ff
        STA     STPTR1          ;LSB stack pointer
        LDA     #SWSTK1/$100    ;>> 8
        STA     STPTR1+1        ;MSB stack pointer
;
; set the NMI vector and initializes the VIA
;
REINIT  LDA     #NMISRV & $FF
        STA     NMIVCT
        LDA     #NMISRV/$100    ; >> 8
        STA     NMIVCT+1

        JSR     INIT22
        JSR     UINIT
        LDA     #ERRNONE        ;report "no error"
        JSR     ERROR
        RTS
;

;*********************************************
;**** MAIN BOOT ROUTINE -- cold start and hard reset
;*********************************************

BOOTR   NOP                     ;warm up
        NOP
        NOP
        JSR     INIT            ;initialize I/O devices

;;initialize pointers, data
        LDA     #INBUFR/256     ;init high byte of input buffer
        STA     INBFPTR+1
        LDA     #0              ;init low-order byte
        STA     INBFPTR
        STA     INHEAD
        STA     INTAIL
        LDA     #ECHO           ;set Echo active.
        STA     FLGREG

;
;main loop for now just checks for a character received
;  into the input buffer, and loops.
;
MAINLP  CLI                     ;enable ACIA interrupts
        JMP     MAINLP
        LDA     INHEAD
        CMP     INTAIL
        BEQ     MAINLP          ;head != tail, must be data
        TAY                     ;use index
        LDA     (INBFPTR),Y     ;get datum
        PHA                     ;save for a moment
        INY                     ;bump pointer
        TYA
        AND     #$7F            ;mask for 128-byte buffer
        STY     INHEAD          ;update pointer
        PLA                     ;recover datum
        JSR     TXMBYT          ;transmit the byte to console
        JMP     MAINLP

;*********************************************
;****  UTILITY ROUTINES
;*********************************************

;
; POLBYT is a get-character routine which resides within
;  the interrupt service routine.  After NMI, the IRQ from VIA
;  is disabled, and the VIA is polled.
;check DTX1 - if non-zero it means (last byte) and (executable)
;When (last byte) and (executable) do not reset busy before returning
;
POLBYT  LDA     #$10            ;check bit 4 interrupt flag
WAIT    BIT     IFR
        BEQ     WAIT
        LDA     IRB             ;get the byte; read the data register
        TAX                     ;  and save it in X
        LDA     DTX1
        BNE     POLRET          ;unless last byte
        STA     ORB             ;  reset BUSY with dummy write
POLRET  TXA
        RTS


;HXNIB is a function - requires an ASCII hexadecimal digit in ACCA
;  and returns its binary equivalent in ACCA
;subtract ASCII '0' from the hex digit
;compare to binary 9
;if was greater than (produced carry)
;subtract 7 more
;return with binary equivalent
;
HXNIB   SEC
        SBC     #$30            ;sub 48 (ASCII '0')
        CMP     #10             ;comparison produces borrow if (A < 10)
        BCC     HXRET           ;go if is good (compare produced no borrow)
        SBC     #7              ;  else subtract 7 more ('@' - '9')
HXRET   RTS



;HXGET is a procedure which waits for two ASCII hex characters
;  and returns the computed binary value in ACCA
;call POLBYT
;call HXNIB
;shift nibble left four bits
;store in (HXBYT) tempy RAM locn
;call POLBYT
;call HXNIB
;inclusive bitwise OR with (HXNIB)
;return with the assembled binary-byte datum
;
HXGET   JSR     POLBYT          ;get first ASCII hex digit
        JSR     HXNIB           ;convert to binary
        ASL     A               ;shift left four places
        ASL     A               ;  to make it a high nybble
        ASL     A
        ASL     A
        STA     HXBYT           ;store temporary high nybble
;
;now second nybble
;
        LDA     EXECABL         ;now DTX1 will be non-zero
        STA     DTX1            ;  if module is executable
        JSR     POLBYT          ;get next ASCII hex digit
        JSR     HXNIB           ;convert to binary
        ORA     HXBYT           ;inclusive OR with high nybble
        RTS

;CKSUMC -- calculate the checksum and read 2 bytes, CR/LF
;if final record (rec type: 1) set flag for 'executable'
;verify the checksum byte when added to the running sum is zero
;if non-zero, go to ERROR as "checksum error
;
CKSUMC  LDA     RECTYPE         ;get record type
        CMP     #1              ;final record?
        BNE     CKS2            ;if final record,
        LDA     LDADDR          ;  inclusive OR load address LSB,MSB
        ORA     LDADDR+1        ;result is non-zero if executable
        STA     EXECABL
CKS2    JSR     HXGET           ;get the binary checksum
        CLC                     ;clear carry flag bit
        ADC     CKSDTUM         ;add the running checksum
        BNE     CKSERR          ;the result should be zero
        RTS
CKSERR  LDA     #ERRCKS         ;error no. 1
        JMP     ERROR           ;go process error

;*********************************************
;**** INTERRUPT SERVICE ROUTINES
;*********************************************

IRQSRV  PHA                     ; save accumulator
        LDA     ASTS            ;check ACIA interrupt
        BMI     ASRV            ;  go if found
        PLA                     ; restore accumulator
        RTI
;
; interrupt service routine for ACIA
;
ASRV    AND     #$08            ;check rcx reg full
        BEQ     NOBYT
        LDA     ARCX            ;get the byte
        JSR     RCXBYT
NOBYT   PLA
        RTI

;NMISRV is NMI interrupt entry, the decision point in this process. It
;  decides whether the CPU is about to receive an Intel HEX file
;  or simply normal I/O channel parallel input.
;disable NMI interrupts
;**** Push all registers so that stack=X/Y/A/P/lsb/msb/...
;read the byte
;if a ':' colon
;  reset BUSY
;  set E-o-f to $00
;  go to START1:
;else is a normal character input, (e.g. header information)
;  goto NMIPRC to process a normal NMI
;
NMISRV  PHA                     ;push A
        LDA     #$10            ;Disable CB1 interrupts to NMI
        STA     IER             ;  immediately
        TYA
        PHA                     ;push Y
        TXA
        PHA                     ;push X
;
        LDA     IRB             ;get the input datum
        CMP     #$3A            ;check for ':' colon as record indicator
        BNE     PROC1A          ;do normal through-put if not
        STA     ORB             ;reset BUSY
        JMP     START1
PROC1A  JMP     NMIPRC          ;process normal input
;

;RT2RET restores all registers from the software stack
;  which maintained them during pre-emption by
;  other subprograms brought into execution.
;Recover all the registers from the software stack,
;  transferring each to the CPU stack.
;Pop the registers, status and return to calling program.
;
RT2RET  SEI                     ;no ints in here, please...
        LDY     STOFST          ;p/u software stack pointer
        DEY                     ;point to P
        LDA     (STPTR1),y      ;recover and push
        PHA
        DEY                     ;point to A
        LDA     (STPTR1),y      ;recover and push
        PHA
        DEY                     ;point to Y
        LDA     (STPTR1),y      ;recover and push
        PHA
        DEY                     ;point to X
        LDA     (STPTR1),y      ;recover and push
        PHA
        STY     STOFST          ;record new stack offset pointer
;
PRGRET  PLA                     ;pop X
        TAX
        PLA                     ;pop Y
        TAY
        PLA                     ;pop A
        RTI                     ;interrupt-related; so use RTI

;NMIRT0 leads in, on certain occasions, to NMIRET
;
NMIRT0  PLA                     ;pop X
        TAX
        PLA                     ;pop Y
        TAY
        PLA                     ;pop A

;NMIRET is a standard return procedure for properly exiting the interrupt
;  service routine.  Does not return - JMP to only.
;enable interrupts
;reset BUSY
;return from interrupt - RTI
;
NMIRET  PHA                     ;save accum
        LDA     #$90            ;set interrupt mask for CB1
        STA     IER             ;Interrupt Enable Register; interrupts on
        STA     ORB             ;reset BUSY
        PLA                     ;restore accum
        RTI


;NMIPRC sends all text input, including any header text to the
;  console, then simply returns from interrupt.
;- might also be used to display module i.d. information etc.
;go to normal proc return
;
NMIPRC  CMP     #$0D
        BEQ     NMIRT0
        CMP     #$0A
        BEQ     NMIRT0
        STA     ATXM            ;shove into transmitter, no error checking
        JMP     NMIRT0

        CMP     #$0D
        BEQ     NMIRT0
        CMP     #$0A
        BEQ     NMIRT0
        JSR     TXMBYT         ;transmit text, headers, etc. to console
        JMP     NMIRT0

;*********************************************
;**** HEX FILE LOADER
;*********************************************

;COLON -- contiguous records loop to this point
;call POLBYT to poll the 6522 for a byte
;
COLON   JSR     POLBYT
        CMP     #$3A            ;check for ':'
        BEQ     START1
        BNE     COLON           ;ignore until next colon found
;
;set End-of-file_record as false; (RECTYPE) <== $00, (DTX1) <== $00
;init reg Y to $00; will be the offset to each load address
;
START1  LDA     #0
        STA     RECTYPE            ;clear E-o-f flag
        STA     DTX1            ;clear POLBYT last-byte flag
        STA     CKSDTUM             ;reset checksum
        STA     EXECABL         ;init to non-executable
        LDY     #0              ;reset offset from load address = $00
;
;get the length.
;store length as counter in BYTCTR, so you will know when @ checksum byte
;add length to (CKSDTUM) for running checksum
;
        JSR     HXGET           ;get length
        STA     RECLEN          ;  and record it
        STA     BYTCTR          ;set byte counter to (reclen)
        CLC                     ;new checksum
        ADC     CKSDTUM
        STA     CKSDTUM
;
;get MSB of load address
;store MSB at (LDADDR + 1)
;add it to checksum
;
STAR1A  JSR     HXGET           ;get the byte and store it
        STA     LDADDR+1
        CLC                     ;new checksum
        ADC     CKSDTUM
        STA     CKSDTUM
;
;get LSB of load address
;store LSB at (LDADDR)
;add it to checksum
;
        JSR     HXGET           ;get the byte and store it
        STA     LDADDR
        CLC                     ;new checksum
        ADC     CKSDTUM
        STA     CKSDTUM
;
;get record type
;store at (DTXX) for just a moment
;add it to checksum
;use type again
;inclusive-OR with (RECTYPE), store in (RECTYPE) to mark E-o-f record
;
        JSR     HXGET           ;get the byte
        STA     RECTYPE         ;store record type
        CLC                     ;new checksum
        ADC     CKSDTUM
        STA     CKSDTUM
;
;Check length at (BYTCTR) - are we out of bytes in this record?
;
PROC2   LDA     BYTCTR
        BEQ     PROC3
;
;else length is not zero (more bytes left to do before checksum)
;call HXGET to get the next 2 chars and return a binary byte in ACCA
;decrement the length counter (BYTCTR -= 1)
;using register Y as the offset,
;  place the byte in memory, indexed indirect, using (LDADDR),Y offset
;increment register Y to account for new offset from current load address
;add the object byte to checksum
;loop to PROC2
;
PROC2A  JSR     HXGET           ;get a binary object byte
        DEC     BYTCTR          ;count down 1 from bytes_left_to_do
        STA     (LDADDR),y      ;put it into memory at the load address
        INY                     ;bump offset to base load address
        CLC                     ;add it to the running checksum
        ADC     CKSDTUM
        STA     CKSDTUM
        JMP     PROC2           ;  and loop
;
;if length at (BYTCTR) is zero now,
;  call CKSUMC, do checksum calculation, setting for last_byte_of_file
;  check the E-o-f by (RECTYPE) != $00
;
PROC3   JSR     CKSUMC          ;
        LDA     #1              ;now DTX0 is non-zero if executing
        CMP     RECTYPE
;
;is not E-o-f, but zero bytes are left
;  so go to COLON: and process another load record
;
        BNE     COLON           ;if not eof record, go for another

;  if E-o-f condition
;  if load address = $0000, which means !((LDADDR) | (LDADDR+1) = $00)
;  go to NMIRET, was only a load module
        LDA     EXECABL
        BNE     PROC3A
        JMP     NMIRT0          ;if zero, then non-executing

;  else assume execution because ((LDADDR) | (LDADDR+1) != $00)
;****save all the registers in the software stack
;*** and stack the address of the register-restore routine
;  push (LDADDR) and (LDADDR+1) into the CPU stack
;  push the status byte
;  go to NMIRET to execute; program will RTS as usual
;
PROC3A  LDY     STOFST
        PLA                     ;get reg X
        STA     (STPTR1),y
        INY
        PLA                     ;get reg Y
        STA     (STPTR1),y
        INY
        PLA                     ;get reg A
        STA     (STPTR1),y
        INY
        PLA                     ;get reg P
        STA     (STPTR1),y
        INY
        STY     STOFST          ;record new stack offset pointer
        TAX                     ;hold P in X for a moment
;
        LDA     #RT2RET/$100    ; >> 8
        PHA                     ;push MSB of regs restore routine
        LDA     #RT2RET         ; & $FF
        PHA                     ;push LSB now
        LDA     LDADDR+1
        PHA                     ;push MSB of exec addr
        LDA     LDADDR
        PHA                     ;push LSB of exec addr
        TXA
        PHA                     ;push processor status
        JMP     NMIRET          ;gracefully exit NMI service and RTI

;
;ERROR routine displays a brief message to the console
;  and returns immediately
;

ERRNONE EQU     0               ;no error
ERRCKS  EQU     1               ;checksum error
ERRTXM  EQU     2               ;transmitter error

TX001   FCB     $0D,$0A
        FCS     ' ERROR='
TX001L  EQU     *-TX001

ERROR   DFB     $5A             ;PHY (cmos), push reg Y
        PHA
        LDY     #0
S0011   LDA     TX001,Y
        DFB     $5A             ;PHY (cmos), push reg Y
        JSR     TXMBYT
        DFB     $7A             ;PLY (cmos), pull reg Y
        INY
        CPY     #TX001L
        BNE     S0011
        PLA
        CLC
        ADC     #$30            ;add ascii '0'
        JSR     TXMBYT
        LDA     #$20
        JSR     TXMBYT
        DFB     $7A             ;PLY (cmos), pull reg Y
        RTS

NEXT    .DS     1

;*********************************************
;**** INTERRUPT AND RESTART VECTORS
;*********************************************

        ORG     $FFF8
        .WORD   BOOTR           ; ?
        .WORD   NMISRV          ; NMI vector
        .WORD   BOOTR           ; Cold start & reset vector
        .WORD   IRQSRV          ; IRQ vector (and BRK vector)

        .END    INIT


