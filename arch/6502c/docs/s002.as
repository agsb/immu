;S002.AS -- 08/11/96
;test program for use with autoloader
;

temp    SET     0               ;variables for temporary use
temp.2  SET     0               ;  exclusively by macros

;'inicmos' is called once regardless
INICMOS MACRO
!       DSEG
        if      CMOS
        else
ACCUM   .DS     1
        endif     ;inicmos
!       CSEG
        ENDM

PHY     MACRO
        if      CMOS
        DFB     $5A     ;PHY, push reg Y
        else
        STA     ACCUM
        TYA
        PHA
        LDA     ACCUM
        endif     ;phy
        ENDM

PLY     MACRO
        if      CMOS
        DFB     $7A     ;PLY, pull reg Y
        else
        STA     ACCUM
        PLA
        TAY
        LDA     ACCUM
        endif   ;ply
        ENDM

;  'D-seg' (set data segment)
;  invoked with argument, sets data segment origin only
;  invoked with no argument, changes location counter to data segment
;
DSEG    MACRO   set.org
t.cseg  SET     *
        IF      0-set.org
dseg    SET     set.org
        ELSE
        ORG     dseg
        ENDIF
        ENDM

CSEG    MACRO
dseg    SET     *
        ORG     t.cseg
        ENDM

SEGINIT MACRO
t.cseg  SET     *         ;initialize temp variables
dseg    SET     0
        ENDM

;end of system macro definitions
;

;print string at address
;string is terminated with NUL (ASCII 0)
;maximum string length: 128 bytes
PRINTA  MACRO   str.addr
        LOCAL   loopr,exitf
        LDY     #0
loopr   LDA     str.addr,Y
        BEQ     exitf
!       PHY
        JSR     TXMBYT
!       PLY
        INY
        BPL     loopr
exitf   NOP
        ENDM

PRINTF  MACRO   string
        LOCAL   TX001,TXLEN,S001,
!       DSEG
TX001   FCS     'string'
TXLEN   EQU     *-TX001
!       CSEG
        LDY     #0
S001    LDA     TX001,Y
!       PHY
        JSR     TXMBYT
!       PLY
        INY
        CPY     #TXLEN
        BNE     S001
        ENDM

;end of user macro definitions

;**************************************************************
;**  MAIN PROGRAM
;**
;
CMOS    SET     -1
TXMBYT  EQU     $F819

CODE    SET     $4000
DATA    SET     CODE-1024

        ORG     CODE
!       SEGINIT
!       DSEG    DATA
!       INICMOS

START   NOP

!       DSEG
TXT01   FCS     'TESTING NUMBER 1'
        FCB     13,10,0
TXT02   FCS     'Now Testing Number 2'
        FCB     13,10,0
TXT03   FCS     'Number three TEST *** '
        FCB     13,10,0
!       CSEG

;
;test of printA

!       PRINTA  TXT01
!       PRINTA  TXT02
!       PRINTA  TXT03

;
;test of printF

!       PRINTF  "Hello... How are you today? "

        NOP
NEXT    EQU     *
        END     START
