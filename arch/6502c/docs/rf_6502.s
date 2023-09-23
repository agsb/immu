; The below is adapted from the fig-FORTH 6502 ASSEMBLY 
; SOURCE LISTING, to apply cc65 assembler syntax and
; orterforth integration requirements. Some of the information
; in the comments no longer applies.

.exportzp N
.exportzp UP
.exportzp XSAVE

ssave = TOS+6

.export _rf_ip: near

_rf_ip := IP

.export _rf_w: near

_rf_w := W

.export _rf_up: near

_rf_up := UP

.export _rf_trampoline

_rf_trampoline:
       LDA _rf_fp               ; return if FP is null
       ORA _rf_fp+1
       BNE trampoline1
       RTS
trampoline1:
       LDA #>(_rf_trampoline-1) ; put return addr on stack
       PHA
       LDA #<(_rf_trampoline-1)
       PHA
       TSX                      ; save S
       STX ssave
       LDX _rf_rp               ; RP-1 to S (high byte is $01)
       DEX
       TXS
       LDX _rf_sp               ; SP to X (high byte is $00)
       LDY #0                   ; set Y to $00, this is expected
       JMP (_rf_fp)             ; jump to FP, return to _rf_trampoline

.export _rf_start

_rf_start:
       STX _rf_sp               ; X to SP
       PLA                      ; save return address (from JSR _rf_start)
       TAY
       PLA
       TSX                      ; S+1 to RP
       INX
       STX _rf_rp
       LDX ssave                ; restore S
       TXS
       PHA                      ; restore return address on stack
       TYA
       PHA
       RTS                      ; return to C

.export _rf_code_cl

_rf_code_cl:
       LDA #2
       PHA
       TYA
       JMP PUSH

.export _rf_code_cs

_rf_code_cs:
       ASL 0,X
       ROL 1,X
       JMP NEXT

.export _rf_code_ln

_rf_code_ln := _rf_next

.export _rf_code_xt

_rf_code_xt:
       STY _rf_fp
       STY _rf_fp+1
       JSR _rf_start
       RTS

.bss

.export _rf_fp

_rf_fp: .res 2

.export _rf_rp

_rf_rp: .res 2

.export _rf_sp

_rf_sp: .res 2

.code

;
;       Through the courtesy of
;
;        FORTH INTEREST GROUP
;           P. O. Box 1105
;      San Carlos, CA   94070
;
;             Release 1.1
;       With compiler security
;               and
;       variable length names
;
; Further distribution must include the above notice
; The FIG Installation Manual is required as it 
; contains the model of FORTH and glossary of the system.
; Available from FIG at the above address for $10.00 postpai
;
; Translated from the FIG Model by W. F. Ragsdale
; with input-output given for the Rockewell System-65.
; Transportation to other systems only requires
; alteration of:  XEMIT, XKEY, XQTER, XCR, and RSLW.
;
;
;   Equates giving memory assigments, machine
;   registers, and disk parameters.
;
;
;TOS   =        ; top of data stack, in z-page.
N      =TOS+8   ; xXxxxxxxx    scratch workspace
IP     =N+8     ;  Xx          interpretive pointer
W      =IP+3    ; xXx          code field pointer
UP     =W+2     ;  Xx          user area pointer
XSAVE  =UP+2    ;  X           temporary for X register
;
;ORIG  =        ; origin of FORTH's dictionary.

.export _rf_code_lit

_rf_code_lit:
       LDA (IP),Y ; <---- start of parameter field
       PHA
       INC IP
       BNE L30
       INC IP+1
L30:   LDA (IP),Y
L31:   INC IP
       BNE PUSH
       INC IP+1
;
PUSH:  DEX
       DEX
;
PUT:   STA 1,X
       PLA
       STA 0,X
;
;     NEXT is the address interpreter that moves from
;     machine level word to word.
;
.export _rf_next
.export NEXT

_rf_next:
NEXT:  LDY #1
       LDA (IP),Y    ; Fetch code address pointed
       STA W+1       ; to by IP
       DEY
       LDA (IP),Y
       STA W
       ; JSR TRACE   ; Remove this when all is well
       CLC           ; Increment IP by two
       LDA IP
       ADC #2
       STA IP
       BCC L54
       INC IP+1
L54:   JMP W-1     ; jump to an indirect jump (W)
;                 which vectors to code pointed by a code fiel

;
;
.export SETUP

SETUP: ASL A
       STA N-1
L63:   LDA 0,X
       STA N,Y
       INX
       INY
       CPY N-1
       BNE L63
       LDY #0
       RTS
;
;                             EXECUTE
;                             SCREEN 14 LINE 11
;
.export _rf_code_exec

_rf_code_exec:
       LDA 0,X
       STA W
       LDA 1,X
       STA W+1
       INX
       INX
       JMP W-1         ; To JMP (W) in z-page
;
;                             BRANCH
;                             SCREEN 15 LINE 1
;
.export _rf_code_bran

_rf_code_bran:
       CLC
       LDA (IP),Y
       ADC IP
       PHA
       INY
       LDA (IP),Y
       ADC IP+1
       STA IP+1
       PLA
       STA IP
       JMP NEXT+2
;
;                             0BRANCH
;                             SCREEN 15 LINE 6
;
.export _rf_code_zbran

_rf_code_zbran:
       INX
       INX
       LDA $FE,X
       ORA $FF,X
       BEQ _rf_code_bran
;
BUMP:  CLC
       LDA IP
       ADC #2
       STA IP
       BCC L122
       INC IP+1
L122:  JMP NEXT
;
;                             (LOOP)
;                             SCREEN 16 LINE 1
;
.export _rf_code_xloop

_rf_code_xloop:
L130:  STX XSAVE
       TSX
       INC $101,X
       BNE PL1
       INC $102,X
;
PL1:   CLC
       LDA $103,X
       SBC $101,X
       LDA $104,X
       SBC $102,X
;
PL2:   LDX XSAVE
       ASL A
       BCC _rf_code_bran
       PLA
       PLA
       PLA
       PLA
       JMP BUMP
;
;                             (+LOOP)
;                             SCREEN 16 LINE 8
;
.export _rf_code_xploo

_rf_code_xploo:
       INX
       INX
       STX XSAVE
       LDA $FF,X
       PHA
       PHA
       LDA $FE,X
       TSX
       INX
       INX
       CLC
       ADC $101,X
       STA $101,X
       PLA
       ADC $102,X
       STA $102,X
       PLA
       BPL PL1
       CLC
       LDA $101,X
       SBC $103,X
       LDA $102,X
       SBC $104,X
       JMP PL2
;
;                             (DO)
;                             SCREEN 17 LINE 2
;
.export _rf_code_xdo
.export POP

_rf_code_xdo:
       LDA 3,X
       PHA
       LDA 2,X
       PHA
       LDA 1,X
       PHA
       LDA 0,X
       PHA
;
POPTWO:INX
       INX
;
_rf_code_drop:
POP:   INX
       INX
       JMP NEXT
;
;                             DIGIT
;                             SCREEN 18 LINE 1
;
.export _rf_code_digit

_rf_code_digit:
       SEC
       LDA 2,X
       SBC #$30
       BMI L234
       CMP #$A
       BMI L227
       SEC
       SBC #7
       CMP #$A
       BMI L234
L227:  CMP 0,X
       BPL L234
       STA 2,X
       LDA #1
       PHA
       TYA
       JMP PUT       ; exit true with converted value
L234:  TYA
       PHA
       INX
       INX
       JMP PUT       ; exit false for bad conversion
;
;                             (FIND)
;                             SCREEN 19 LINE 1
;
.export _rf_code_pfind

_rf_code_pfind:
       LDA #2
       JSR SETUP
       STX XSAVE
L249:  LDY #0
       LDA (N),Y
       EOR (N+2),Y
       AND #$3F
       BNE L281
L254:  INY
       LDA (N),Y
       EOR (N+2),Y
       ASL A
       BNE L280
       BCC L254
       LDX XSAVE
       DEX
       DEX
       DEX
       DEX
       CLC
       TYA
       ADC #5
       ADC N
       STA 2,X
       LDY #0
       TYA
       ADC N+1
       STA 3,X
       STY 1,X
       LDA (N),Y
       STA 0,X
       LDA #1
       PHA
       JMP PUSH
L280:  BCS L284
L281:  INY
       LDA (N),Y
       BPL L281
L284:  INY
       LDA (N),Y
       TAX
       INY
       LDA (N),Y
       STA N+1
       STX N
       ORA N
       BNE L249
       LDX XSAVE
       LDA #0
       PHA
       JMP PUSH     ; exit false upon reading null link
;
;                             ENCLOSE
;                             SCREEN 20 LINE 1
;
.export _rf_code_encl

_rf_code_encl:
       LDA #2
       JSR SETUP
       TXA
       SEC
       SBC #8
       TAX
       STY 3,X
       STY 1,X
       DEY
L313:  INY
       LDA (N+2),Y
       CMP N
       BEQ L313
       STY 4,X
L318:  LDA (N+2),Y
       BNE L327
       STY 2,X
       STY 0,X
       TYA
       CMP 4,X
       BNE L326
       INC 2,X
L326:  JMP NEXT
L327:  STY 2,X
       INY
       CMP N
       BNE L318
       STY 0,X
       JMP NEXT
;
;                             CMOVE
;                             SCREEN 22 LINE 1
;
.export _rf_code_cmove

_rf_code_cmove:
       LDA #3
       JSR SETUP
L370:  CPY N
       BNE L375
       DEC N+1
       BPL L375
       JMP NEXT
L375:  LDA (N+4),Y
       STA (N+2),Y
       INY
       BNE L370
       INC N+5
       INC N+3
       JMP L370
;
;                             U*
;                             SCREEN 23 LINE 1
;
.export _rf_code_ustar

_rf_code_ustar:
       LDA 2,X
       STA N
       STY 2,X
       LDA 3,X
       STA N+1
       STY 3,X
       LDY #16       ; for 16 bits
L396:  ASL 2,X
       ROL 3,X
       ROL 0,X
       ROL 1,X
       BCC L411
       CLC
       LDA N
       ADC 2,X
       STA 2,X
       LDA N+1
       ADC 3,X
       STA 3,X
       ; LDA #0
       ; ADC 0,X
       ; STA 0,X
       BCC L411
       INC 0,X
       BNE L411
       INC 1,X
L411:  DEY
       BNE L396
       JMP NEXT
;
;                             U/
;                             SCREEN 24 LINE 1
;
.export _rf_code_uslas

_rf_code_uslas:
;        LDA 4,X
;        LDY 2,X
;        STY 4,X
;        ASL A
;        STA 2,X
;        LDA 5,X
;        LDY 3,X
;        STY 5,X
;        ROL A
;        STA 3,X
;        LDA #16       ; for 16 bits
;        STA N
; L433:  ROL 4,X
;        ROL 5,X
;        SEC
;        LDA 4,X
;        SBC 0,X
;        TAY
;        LDA 5,X
;        SBC 1,X
;        BCC L444
;        STY 4,X
;        STA 5,X
; L444:  ROL 2,X
;        ROL 3,X
;        DEC N
;        BNE L433
;        JMP POP

; https://dwheeler.com/6502/ummod.txt

; The following is Garth Wilson's corrected UM/MOD code for Forth,
; compared to the buggy fig-Forth, per
; http://6502.org/source/integers/ummodfix/ummodfix.htm


; HEADER "UM/MOD", NOT_IMMEDIATE          ; ( ud u -- rem quot )
;         CODE            ; (Make Forth CFA point to PFA for a code definition.)

        SEC
        LDA     2,X     ; Subtract hi cell of dividend by
        SBC     0,X     ; divisor to see if there's an overflow condition.
        LDA     3,X
        SBC     1,X
        BCS     ofloS   ; Branch if /0 or overflow.

        LDA     #11H    ; Loop 17x.
        STA     N       ; Use N for loop counter.
 loop:  ROL     4,X     ; Rotate dividend lo cell left one bit.
        ROL     5,X
        DEC     N       ; Decrement loop counter.
        BEQ     endS    ; If we're done, then branch to end.
        ROL     2,X     ; Otherwise rotate dividend hi cell left one bit.
        ROL     3,X
;       STZ     N+1
        LDA     #0
        STA     N+1

        ROL     N+1     ; Rotate the bit carried out of above into N+1.

        SEC
        LDA     2,X     ; Subtract dividend hi cell minus divisor.
        SBC     0,X
        STA     N+2     ; Put result temporarily in N+2 (lo byte)
        LDA     3,X
        SBC     1,X
        TAY             ; and Y (hi byte).
        LDA     N+1     ; Remember now to bring in the bit carried out above.
        SBC     #0
        BCC     loop

        LDA     N+2     ; If that didn't cause a borrow,
        STA     2,X     ; make the result from above to
        STY     3,X     ; be the new dividend hi cell
;       BRA     loop    ; and then brach up.  (NMOS 6502 can use BCS here.)
        BCS     loop

 ofloS: LDA     #0FFH   ; If overflow or /0 condition found,
        STA     2,X     ; just put FFFF in both the remainder
        STA     3,X
        STA     4,X     ; and the quotient.
        STA     5,X

 endS:  INX             ; When you're done, show one less cell on data stack,
        INX             ; (INX INX is exactly what the Forth word DROP does) 
;       JMP     SWAP    ; and swap the two top cells to put quotient on top.
                        ; (Actually you'll jump to the beginning of SWAP's
                        ; executable code.  Assembler label "SWAP" is at SWAP's
                        ; PFA, not the CFA that ' SWAP would give you in Forth.
        JMP     _rf_code_swap
;-------------------

;
;                             AND
;                             SCREEN 25 LINE 2
;
.export _rf_code_andd

_rf_code_andd:
       LDA 0,X
       AND 2,X
       PHA
       LDA 1,X
       AND 3,X
;
BINARY:INX
       INX
       JMP PUT
;
;                             OR
;                             SCREEN 25 LINE 7
;
.export _rf_code_orr

_rf_code_orr:
       LDA 0,X
       ORA 2,X
       PHA
       LDA 1,X
       ORA 3,X
       INX
       INX
       JMP PUT
;
;                             XOR
;                             SCREEN 25 LINE 11
;
.export _rf_code_xorr

_rf_code_xorr:
       LDA 0,X
       EOR 2,X
       PHA
       LDA 1,X
       EOR 3,X
       INX
       INX
       JMP PUT
;
;                             SP@
;                             SCREEN 26 LINE 1
;
.export _rf_code_spat
.export PUSH0A

_rf_code_spat:
       TXA
;
PUSH0A:PHA
       LDA #0
       JMP PUSH
;
;                             SP!
;                             SCREEN 26 LINE 5
;
.export _rf_code_spsto

_rf_code_spsto:
       LDY #6
       LDA (UP),Y   ; load data stack pointer (X-reg) from
       TAX          ; silent user variable S0.
       JMP NEXT
;
;                             RP!
;                             SCREEN 26 LINE 8
;
.export _rf_code_rpsto

_rf_code_rpsto:
       STX XSAVE    ; load return stack pointer
       LDY #8       ; (machine stack pointer) from
       LDA (UP),Y   ; silent user variable R0.
       TAX
       TXS
       LDX XSAVE
       JMP NEXT
;
;                             ;S
;                             SCREEN 26 LINE 12
;
.export _rf_code_semis

_rf_code_semis:
       PLA
       STA IP
       PLA
       STA IP+1
       JMP NEXT
;
;                             LEAVE
;                             SCREEN 27 LINE 1
;
.export _rf_code_leave

_rf_code_leave:
       STX XSAVE
       TSX
       LDA $101,X
       STA $103,X
       LDA $102,X
       STA $104,X
       LDX XSAVE
       JMP NEXT
;
;                             >R
;                             SCREEN 27 LINE 5
;
.export _rf_code_tor

_rf_code_tor:
       LDA 1,X      ; move high byte
       PHA
       LDA 0,X      ; then low byte
       PHA          ; to return stack
       INX
       INX          ; popping off data stack
       JMP NEXT
;
;                             R>
;                             SCREEN 27 LINE 8
;
.export _rf_code_fromr

_rf_code_fromr:
       DEX          ; make room on data stack
       DEX
       PLA          ; high byte
       STA 0,X
       PLA          ; then low byte
       STA 1,X      ; restored to data stack
       JMP NEXT
;
;                             R
;                             SCREEN 27 LINE 11
;
.export _rf_code_rr

_rf_code_rr:
       STX XSAVE
       TSX          ; address return stack.
       LDA $101,X   ; copy bottom value
       PHA          ; to data stack.
       LDA $102,X
       LDX XSAVE
       JMP PUSH
;
;                             0=
;                             SCREEN 28 LINE 2
;
.export _rf_code_zequ

_rf_code_zequ:
       LDA 0,X
       ORA 1,X
       STY 1,X
       BNE L613
       INY
L613:  STY 0,X
       JMP NEXT
;
;                             0<
;                             SCREEN 28 LINE 6
;
.export _rf_code_zless

_rf_code_zless:
       ASL 1,X
       TYA
       ROL A
       STY 1,X
       STA 0,X
       JMP NEXT
;
;                             +
;                             SCREEN 29 LINE 1
;
.export _rf_code_plus

_rf_code_plus:
       CLC
       LDA 0,X
       ADC 2,X
       STA 2,X
       LDA 1,X
       ADC 3,X
       STA 3,X
       INX
       INX
       JMP NEXT
;
;                             D+
;                             SCREEN 29 LINE 4
;
.export _rf_code_dplus

_rf_code_dplus:
       CLC
       LDA 2,X
       ADC 6,X
       STA 6,X
       LDA 3,X
       ADC 7,X
       STA 7,X
       LDA 0,X
       ADC 4,X
       STA 4,X
       LDA 1,X
       ADC 5,X
       STA 5,X
       JMP POPTWO
;
;                             MINUS
;                             SCREEN 29 LINE 9
;
.export _rf_code_minus

_rf_code_minus:
       SEC
       TYA
       SBC 0,X
       STA 0,X
       TYA
       SBC 1,X
       STA 1,X
       JMP NEXT
;
;                             DMINUS
;                             SCREEN 29 LINE 12
;
.export _rf_code_dminu

_rf_code_dminu:
       SEC
       TYA
       SBC 2,X
       STA 2,X
       TYA
       SBC 3,X
       STA 3,X
       JMP _rf_code_minus+1
;
;                             OVER
;                             SCREEN 30 LINE 1
;
.export _rf_code_over

_rf_code_over:
       LDA 2,X
       PHA
       LDA 3,X
       JMP PUSH
;
;                             DROP
;                             SCREEN 30 LINE 4
;
.export _rf_code_drop
;
;                             SWAP
;                             SCREEN 30 LINE 8
;
.export _rf_code_swap

_rf_code_swap:
       LDA 2,X
       PHA
       LDA 0,X
       STA 2,X
       LDA 3,X
       LDY 1,X
       STY 3,X
       JMP PUT
;
;                             DUP
;                             SCREEN 30 LINE 12
;
.export _rf_code_dup

_rf_code_dup:
       LDA 0,X
       PHA
       LDA 1,X
       JMP PUSH
;
;                             +!
;                             SCREEN 31 LINE 2
;
.export _rf_code_pstor

_rf_code_pstor:
       CLC
       LDA (0,X)    ; fetch 16-bit value addressed
       ADC 2,X      ; by bottom of stack, adding to
       STA (0,X)    ; second item on stack, and
       INC 0,X      ; and return to memory.
       BNE L754
       INC 1,X
L754:  LDA (0,X)
       ADC 3,X
       STA (0,X)
       JMP POPTWO
;
;                             TOGGLE
;                             SCREEN 31 LINE 7
;
.export _rf_code_toggl

_rf_code_toggl:
       LDA (2,X)    ; complement bits in memory address
       EOR 0,X      ; second on stack, by pattern
       STA (2,X)    ; on bottom of stack.
       JMP POPTWO
;
;                             @
;                             SCREEN 32 LINE 1
;
.export _rf_code_at

_rf_code_at:
       LDA (0,X)
       PHA
       INC 0,X
       BNE L781
       INC 1,X
L781:  LDA (0,X)
       JMP PUT
;
;                             C@
;                             SCREEN 32 LINE 5
;
.export _rf_code_cat

_rf_code_cat:
       LDA (0,X)    ; fetch byte addressed by bottom
       STA 0,X      ; of stack to stack, zeroing
       STY 1,X      ; the high byte.
       JMP NEXT
;
;                             !
;                             SCREEN 32 LINE 8
;
.export _rf_code_store

_rf_code_store:
       LDA 2,X
       STA (0,X)    ; store second 16-bit value on stack
       INC 0,X      ; to memory as addresses by
       BNE L806
       INC 1,X      ; bottom of stack.
L806:  LDA 3,X
       STA (0,X)
       JMP POPTWO
;
;                             C!
;                             SCREEN 32 LINE 12
;
.export _rf_code_cstor

_rf_code_cstor:
       LDA 2,X
       STA (0,X)
       JMP POPTWO

.export _rf_code_docol

_rf_code_docol:
;
DOCOL: LDA IP+1
       PHA
       LDA IP
       PHA
       ; JSR TCOLON     ; Mark the start of a traced : def.
       CLC
       LDA W
       ADC #2
       STA IP
       TYA
       ADC W+1
       STA IP+1
       JMP NEXT

.export _rf_code_docon

_rf_code_docon:
;
DOCON: LDY #2
       LDA (W),Y
       PHA
       INY
       LDA (W),Y
       JMP PUSH

.export _rf_code_dovar

_rf_code_dovar:
;
DOVAR: CLC
       LDA W
       ADC #2
       PHA
       TYA
       ADC W+1
       JMP PUSH

.export _rf_code_douse

_rf_code_douse:
;
DOUSE: LDY #2
       CLC
       LDA (W),Y
       ADC UP
       PHA
       LDA #0
       ADC UP+1
       JMP PUSH

.export _rf_code_dodoe

_rf_code_dodoe:
;
DODOE: LDA IP+1
       PHA
       LDA IP
       PHA
       LDY #2
       LDA (W),Y
       STA IP
       INY
       LDA (W),Y
       STA IP+1
       CLC
       LDA W
       ADC #4
       PHA
       LDA W+1
       ADC #0
       JMP PUSH

.export _rf_code_cold

_rf_code_cold:
; This preamble modifies the following code to hold the
; parameter field addresses required. The original Forth
; model source compiled these values inline using the 
; Forth 6502 assembler, which we cannot do. The rest of
; the code is close to the original.
cold1: LDA ORIG+$22 ; move FORTH field to cold3 and cold4
       STA cold3+1
       STA cold4+1
       LDA ORIG+$23
       STA cold3+2
       STA cold4+2
       INC cold4+1  ; increment cold4 by 1
       BNE cold2
       INC cold4+2
cold2: LDA ORIG+$25 ; move ABORT PFA to cold7, cold8
       STA cold7+1
       LDA ORIG+$24
       STA cold8+1

       LDA ORIG+$0C ; from cold start area
cold3: STA $FFFF    ; self modified
       LDA ORIG+$0D
cold4: STA $FFFF    ; self modified
       LDY #$15
       BNE L2433
WARM:  LDY #$0F
L2433: LDA ORIG+$10
       STA UP
       LDA ORIG+$11
       STA UP+1
L2437: LDA ORIG+$0C,Y
       STA (UP),Y
       DEY
       BPL L2437
cold7: LDA #$FF     ; self modified
       STA IP+1
cold8: LDA #$FF     ; self modified
       STA IP
       CLD
       LDA #$6C
       STA W-1
       JMP _rf_code_rpsto ; And off we go!
;
;                             S->D
;                             SCREEN 56 LINE 1
;
.export _rf_code_stod

_rf_code_stod:
       LDA 1,X
       BPL stod1
       DEY
stod1:
       TYA
       PHA
       JMP PUSH
