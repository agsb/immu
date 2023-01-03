;S001.AS -- 08/10/96
;example program to demonstrate the use of macros with MAS65
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

;end of macro definitions

;**************************************************************
;**
;**
;
CMOS    SET     -1
TXMBYT  EQU     $F819

BASE    SET     $4000
        ORG     BASE
!       SEGINIT
!       DSEG    $3C00
!       INICMOS

S0010   LDY     #0
S0011   LDA     TX001,Y
!       PHY
        JSR     TXMBYT
!       PLY
        INY
        CPY     #TXLEN
        BNE     S0011
        RTS

!       DSEG
TX001   FCS     'THIS IS A TEST.'
TXLEN   EQU     *-TX001
!       CSEG

        NOP
NEXT    EQU     *
        END     S0010
