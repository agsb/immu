\ T3XFORTH Meta Compiler
\ Nils M Holm, 2021
\ In the public domain / under the CC0 license

\ This is a very simple compiler for a subset of T3XFORTH that
\ is barely sufficient to bootstrap the high-level part of the
\ T3XFORTH kernel. It does not include an assembler; the CODE
\ words are copied from the kernel running the meta compiler.

VOCABULARY META-COMPILER  META-COMPILER DEFINITIONS

\ Where the system sources reside
: SOURCE-BLOCKS ( -- u1 u2 ) 70 119 ;

\ Where to put the new kernel
[HEX] 6000 CONSTANT KERNEL-SPACE

\ Reserved memory at bottom of address space
256 CONSTANT RESERVED

\ Flags
[HEX] 80 CONSTANT IMMEDIATE-FLAG
[HEX] 40 CONSTANT COMP-ONLY-FLAG

VARIABLE DICTIONARY  \ Dictionary of new kernel

\ For caching frequently-used words
VARIABLE DOCOLON       VARIABLE DODO
VARIABLE DOVAR         VARIABLE DOLOOP
VARIABLE DOCONST       VARIABLE DO+LOOP
VARIABLE DOBRANCH      VARIABLE DO/LOOP
VARIABLE DO0BRANCH     VARIABLE DOEXIT
VARIABLE DOLIT
VARIABLE DO$"          VARIABLE DOABORT"

VARIABLE RESETVEC  \ See RESET in T3XFORT?.S86

VARIABLE M-H  \ Kernel space HERE pointer

\ Is the word at NFA a CODE word?
: ?CODE ( nfa -- f ) DUP >PFA SWAP >CFA @ = ;

\ Find NFA and end of last CODE word in memory
: LAST-CODE-WORD ( -- nfa a )
  (FORTH) @ DUP >LFA @  BEGIN DUP WHILE
    DUP ?CODE IF EXIT THEN
    SWAP >LFA @ SWAP >LFA @  REPEAT ;

\ Copy T3XFORTH VM to bottom of kernel space
: COPY-CODE ( -- ) LAST-CODE-WORD KERNEL-SPACE + DICTIONARY !
  0 KERNEL-SPACE  ROT  DUP >R CMOVE
  R> KERNEL-SPACE + DUP  M-H !  5 - RESETVEC !  ;

\ Report compilation error in the form
\ META-COMPILER: a1: a2
\ and then abort; if A1 is 0, ignore it.
: ERROR ( a1 a2 -- ) CR ." META-COMPILER: "  COUNT TYPE
  ?DUP IF ." : " COUNT TYPE THEN  CR ABORT ;

\ Look up word in kernel space
: M-LOOKUP ( a -- a T | F ) DUP UPCASE  DICTIONARY @
  KERNEL-SPACE - BEGIN ?DUP WHILE KERNEL-SPACE +
    2DUP ?SAME IF NIP KERNEL-SPACE - -1 EXIT THEN
    >LFA @ REPEAT  DROP 0 ;

: NOT-FOUND ( -- ) $" NOT FOUND" ERROR ;

\ Find word in kernel space, fail when not found.
\ Return PFA upon success.
: M-FIND ( a -- a ) DUP M-LOOKUP IF NIP >CFA EXIT THEN
  NOT-FOUND ;

\ String containing $"
: $"-STR ( -- a ) $" $x" [CHAR] " OVER 2 + C! ;

\ String containing ($")
: ($")-STR ( -- a ) $" ($x)" [CHAR] " OVER 3 + C! ;

\ String containing ABORT"
: ABORT"-STR ( -- a ) $" ABORTx" [CHAR] " OVER 6 + C! ;

\ String containing (ABORT")
: (ABORT")-STR ( -- a ) $" (ABORTx)" [CHAR] " OVER 7 + C! ;

\ The following words resemble T3XFORTH words, but write
\ to kernel space instead of the regular dictionary space

: M-HERE ( -- a ) M-H @ ;

: M-ALLOT ( u -- ) M-H +! ;

: M-C, ( -- ) M-H @ C!  1 M-H +! ;
: M-,  ( -- ) M-H @  !  2 M-H +! ;

VARIABLE M-LAST

: M-CREATE ( -- ) BL WORD DUP ENTRY  M-HERE 6 CMOVE
  6 M-ALLOT  DICTIONARY @ KERNEL-SPACE - M-,  DOVAR @ M-,
  M-HERE >NFA M-LAST ! ;

: M-LINK ( -- ) M-LAST @ DICTIONARY ! ;

: M-; ( -- ) DOEXIT @ M-, M-LINK ;

: M-MARK ( -- a ) M-HERE 0 M-, ;
: M-RESOLVE ( a -- ) M-HERE KERNEL-SPACE - SWAP ! ;

: M-IF   ( -- a )   DO0BRANCH @ M-, M-MARK ;
: M-ELSE ( -- a )   DOBRANCH @ M-, M-MARK SWAP M-RESOLVE ;
: M-THEN ( a -- a ) M-RESOLVE ;

: M-BEGIN  ( -- a )  M-HERE KERNEL-SPACE - ;
: M-AGAIN  ( a -- )  DOBRANCH @ M-, M-, ;
: M-WHILE  ( a -- )  M-IF ;
: M-REPEAT ( a -- )  DOBRANCH @ M-, SWAP M-, M-RESOLVE ;
: M-UNTIL  ( a -- )  DO0BRANCH @ M-, M-, ;

: M-DO    ( -- a ) DODO @ M-, M-HERE KERNEL-SPACE - ;
: M-LOOP  ( -- a ) DOLOOP @ M-, M-, ;
: M-+LOOP ( -- a ) DO+LOOP @ M-, M-, ;
: M-/LOOP ( -- a ) DO/LOOP @ M-, M-, ;

: M-LITERAL ( w -- ) DOLIT @ M-, M-, ;

\ Change CFA of most recently CREATEd word
: SET-CODE ( a -- ) M-H @ >NFA >CFA M-H !  M-, ;

: M-VARIABLE ( -- ) M-CREATE 0 M-, M-LINK ;

: M-CONSTANT ( w -- ) M-CREATE DOCONST @ SET-CODE M-, M-LINK ;

: M-' ( -- a ) BL WORD DUP M-LOOKUP IF NIP >PFA EXIT THEN
  NOT-FOUND ;

: M-DEFER ( -- ) M-CREATE DOCOLON @ SET-CODE 0 M-,
  DOEXIT @ M-, M-LINK ;

: M-IS ( -- )
  M-LAST @ KERNEL-SPACE - >CFA M-' KERNEL-SPACE + ! ;

: COMP-STRING ( a -- ) M-HERE OVER C@ 1+ CMOVE
  M-HERE C@ 1+ M-ALLOT ;

: M-$" ( -- ) DO$" @ 0= IF ($")-STR M-FIND DO$" ! THEN
  DO$" @ M-, [CHAR] " WORD COMP-STRING ;

: M-ABORT" ( -- ) DOABORT" @ 0= IF
   (ABORT")-STR M-FIND DOABORT" ! THEN
  DOABORT" @ M-, [CHAR] " WORD COMP-STRING ;

\ Set flags of most recently CREATEd word
: SET-FLAG ( w -- ) M-LAST @ C@ OR M-LAST @ C! ;

: M-IMMEDIATE ( -- ) IMMEDIATE-FLAG SET-FLAG ;
: M-COMP-ONLY ( -- ) COMP-ONLY-FLAG SET-FLAG ;

: M-[HEX]  ( -- w ) [COMPILE] [HEX] ;
: M-[CHAR] ( -- c ) [COMPILE] [CHAR] M-LITERAL ;
: M-[']    ( --  )  M-' M-LITERAL ;

: M-[COMPILE] ( -- ) M-' PFA>CFA M-, ;

\ Store in kernel space
: M-! ( w a -- ) KERNEL-SPACE + ! ;

\ Are two packed strings equal? Leave A1 on stack
: =WORD ( a1 a2 -- a1 f ) OVER DUP C@ 1+ PAD SWAP CMOVE
  PAD UPCASE PAD DUP C@ 1+ ROT -TEXT 0= ;

\ Compile word at NFA, report error if immediate;
\ "A" is a packed string naming the word.
: COMP ( a nfa -- a )
  DUP KERNEL-SPACE + C@ IMMEDIATE-FLAG AND IF
    OVER $" UNKNOWN IMMEDIATE" ERROR THEN  >CFA M-, ;

\ Kernel-space colon compiler, continued
: M3-: ( -- ) 
    $"-STR        =WORD IF DROP M-$"              ELSE
    $" [CHAR]"    =WORD IF DROP M-[CHAR]          ELSE
    $" [HEX]"     =WORD IF DROP M-[HEX] M-LITERAL ELSE
    $" [COMPILE]" =WORD IF DROP M-[COMPILE]       ELSE
    ABORT"-STR    =WORD IF DROP M-ABORT"          ELSE
    DUP M-LOOKUP        IF COMP DROP              ELSE
    DUP ?NUMBER         IF M-LITERAL DROP         ELSE
      NOT-FOUND
    THEN THEN THEN THEN THEN THEN THEN ;

\ Kernel-space colon compiler, continued
: M2-: ( -- ) 
    $" BEGIN"  =WORD IF DROP M-BEGIN    ELSE
    $" AGAIN"  =WORD IF DROP M-AGAIN    ELSE
    $" UNTIL"  =WORD IF DROP M-UNTIL    ELSE
    $" WHILE"  =WORD IF DROP M-WHILE    ELSE
    $" REPEAT" =WORD IF DROP M-REPEAT   ELSE
    $" +LOOP"  =WORD IF DROP M-+LOOP    ELSE
    $" /LOOP"  =WORD IF DROP M-/LOOP    ELSE
    $" [']"    =WORD IF DROP M-[']      ELSE
      M3-:
    THEN THEN THEN THEN THEN THEN THEN THEN ;

\ Kernel-space colon compiler
: M-: ( -- ) M-CREATE DOCOLON @ SET-CODE
  BEGIN BL WORD DUP C@ WHILE
    $" ("     =WORD IF DROP [COMPILE] ( ELSE
    $" \"     =WORD IF DROP [COMPILE] \ ELSE
    $" ;"     =WORD IF DROP M-; EXIT    ELSE
    $" IF"    =WORD IF DROP M-IF        ELSE
    $" THEN"  =WORD IF DROP M-THEN      ELSE
    $" ELSE"  =WORD IF DROP M-ELSE      ELSE
    $" DO"    =WORD IF DROP M-DO        ELSE
    $" LOOP"  =WORD IF DROP M-LOOP      ELSE
      M2-:
    THEN THEN THEN THEN THEN THEN THEN THEN
  REPEAT DROP ;

\ Metacircular interpreter, continued
: M2-INTERPRET ( -- )
    $" '"         =WORD IF DROP M-'         ELSE
    $" !"         =WORD IF DROP M-!         ELSE
    $" DEFER"     =WORD IF DROP M-DEFER     ELSE
    $" IS"        =WORD IF DROP M-IS        ELSE
    $" >NFA"      =WORD IF DROP >NFA        ELSE
    DUP ?NUMBER         IF NIP              ELSE
      NOT-FOUND
    THEN THEN THEN THEN THEN THEN ;

\ Metacircular interpreter
: M-INTERPRET ( -- ) BEGIN BL WORD DUP C@ WHILE
    $" ("         =WORD IF DROP [COMPILE] ( ELSE
    $" \"         =WORD IF DROP [COMPILE] \ ELSE
    $" :"         =WORD IF DROP M-:         ELSE
    $" IMMEDIATE" =WORD IF DROP M-IMMEDIATE ELSE
    $" COMPILE-ONLY"
                  =WORD IF DROP M-COMP-ONLY ELSE
    $" VARIABLE"  =WORD IF DROP M-VARIABLE  ELSE
    $" CONSTANT"  =WORD IF DROP M-CONSTANT  ELSE
    $" [HEX]"     =WORD IF DROP M-[HEX]     ELSE
      M2-INTERPRET
    THEN THEN THEN THEN THEN THEN THEN THEN
  REPEAT DROP ;

\ Load and meta-interpret block
: M-LOAD ( u -- )
  BLK @ >R  >IN @ >R  #TIB @ >R  ACTIVE @ >R
  DUP BLOCK DROP BLK !  B/BUF #TIB !  0 >IN !
  M-INTERPRET
  R> ACTIVE !  R> #TIB !  R> >IN !  R> BLK ! ;

\ Initial state setup
: SETUP ( -- ) PAD B/BUF + KERNEL-SPACE U> IF
    0 $" TOO LITTLE SPACE" ERROR THEN  COPY-CODE
  $" (COLON)"   M-FIND CFA>PFA DOCOLON   !
  $" (VAR)"     M-FIND CFA>PFA DOVAR     !
  $" (CONST)"   M-FIND CFA>PFA DOCONST   !
  $" (BRANCH)"  M-FIND         DOBRANCH  !
  $" (0BRANCH)" M-FIND         DO0BRANCH !
  $" (LIT)"     M-FIND         DOLIT     !
  $" (DO)"      M-FIND         DODO      !
  $" (LOOP)"    M-FIND         DOLOOP    !
  $" (+LOOP)"   M-FIND         DO+LOOP   !
  $" (/LOOP)"   M-FIND         DO/LOOP   !
  $" EXIT"      M-FIND         DOEXIT    ! ;

\ Set kernel-space variable at A2 to image address A1
: SET-VAR ( a1 a2 -- ) M-FIND KERNEL-SPACE + CFA>PFA 
  SWAP KERNEL-SPACE - SWAP ! ;

\ Initialize variables and reset vector of the new kernel
: INIT-VARS ( -- ) M-HERE $" H" SET-VAR
  DICTIONARY @ $" (FORTH)" SET-VAR
  $" RESET" M-FIND CFA>PFA RESETVEC @ ! ;

\ Meta compiler
: BUILD-SYSTEM ( -- ) SETUP
  SOURCE-BLOCKS 1+ SWAP DO I . I M-LOAD LOOP INIT-VARS ;

: IMAGE-SIZE ( -- ) M-HERE KERNEL-SPACE - RESERVED - ;

\ Write kernel to system blocks
: DUMP-SYSTEM ( u -- )
  M-HERE KERNEL-SPACE - RESERVED - B/BUF 1- + B/BUF / 0 DO
    I B/BUF * RESERVED + KERNEL-SPACE +
    I 33 + BUFFER B/BUF CMOVE  UPDATE FLUSH  I 33 + . LOOP
    EMPTY-BUFFERS  IMAGE-SIZE . ;

FORTH DEFINITIONS

META-COMPILER : META-COMPILE ( -- ) CR ." COMPILING: "
  BUILD-SYSTEM CR ." SAVING IMAGE: " DUMP-SYSTEM ; FORTH

