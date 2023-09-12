\ T3XFORTH High-Level Words
\ Nils M Holm, 2021
\ Public domain / CC0 License

: ?DUP ( w -- w w | w ) DUP IF DUP THEN ;

: NIP ( w1 w2 -- w2 ) SWAP DROP ;
    
: ROT ( w1 w2 w3 -- w2 w3 w1 ) >R SWAP R> SWAP ;

: -ROT ( w1 w2 w3 -- w3 w1 w2 ) ROT ROT ;

: 2DROP ( d -- ) DROP DROP ;
      
: 2DUP ( d -- d d ) OVER OVER ;

: 2SWAP ( d1 d2 -- d2 d1 ) >R -ROT R> -ROT ;

-1 CONSTANT -1
 0 CONSTANT  0
 1 CONSTANT  1
 2 CONSTANT  2

: INVERT ( w -- w ) -1 XOR ;

: + ( n n -- n ) UM+ DROP ;

: 1+ ( n -- n ) 1 + ;
: 2+ ( n -- n ) 2 + ;

: NEGATE ( n -- n ) INVERT 1+ ;

: DNEGATE ( d -- d ) INVERT >R INVERT 1 UM+ R> + ;

: - ( n n -- n ) NEGATE + ;

: 1- ( n -- n ) 1 - ;
: 2- ( n -- n ) 2 - ;

: ABS ( n -- n ) DUP 0< IF NEGATE THEN ;

: 0= ( w -- f ) IF 0 EXIT THEN -1 ;

: NOT ( w -- f ) 0= ;

:  = ( w w -- f ) XOR 0= ;
: <> ( w w -- f ) = 0= ;

: U< ( u u -- f ) 2DUP XOR 0< IF  NIP 0< EXIT THEN - 0< ;
:  < ( n n -- f ) 2DUP XOR 0< IF DROP 0< EXIT THEN - 0< ;

: U> ( u u -- f ) SWAP U< ;
:  > ( n n -- f ) SWAP < ;

: 0> ( n -- f ) 0 > ;

: D+ ( d d -- d ) >R ROT UM+ ROT + R> + ;

: D< ( d d -- f ) ROT SWAP < IF 2DROP -1 EXIT THEN U< ;

: MAX ( n n -- n ) 2DUP < IF SWAP THEN DROP ;
: MIN ( n n -- n ) 2DUP > IF SWAP THEN DROP ;

: WITHIN ( u ul uh -- f ) OVER - >R - R> U< ;

: UM* ( u1 u2 -- ud )
  0 SWAP ( u1 v=0 u2 ) 16 0 DO
    DUP UM+ >R >R     \ u1 v         ; cu2 2u2
    DUP UM+  R> +     \ u1 2v 2u2+cv ; cu2
    R> IF             \ u1 2v 2u2+cv cu2
    >R OVER           \ u1 2v u1     ; 2u2+cv
    UM+  R> + THEN    \ u1 2v+u1 2u2+cv+c
  LOOP ROT DROP ;

: * ( w w -- w ) UM* DROP ;

: M* ( n n -- d )
  2DUP XOR 0< >R  ABS SWAP ABS UM*  R> IF DNEGATE THEN ;

: 2* ( w -- w ) 1 LSHIFT ;
: 2/ ( w -- w ) 1 RSHIFT ;

: UM/MOD ( ul uh u -- um uq )
  2DUP U<                    \ uh < u
  IF  NEGATE                 \ ul uh -u
    16 0 DO
      >R DUP  UM+  >R >R     \ ul          ;  -u ch 2uh
      DUP UM+  R> +          \ 2ul 2uh+cl  ;  -u ch
      DUP R> R@ SWAP >R      \ 2ul 2uh+cl 2uh+cl -u  ; -u ch
          UM+ R> OR          \ 2ul 2uh+cl 2uh+cl-u c|ch ; -u
      IF >R DROP 1+ R> ELSE  \ 2ul+1 2uh+cl-u ; -u
         DROP THEN           \ 2ul 2uh+cl     ; -u
    R> LOOP DROP SWAP EXIT
  THEN  DROP 2DROP  -1 DUP ;

: U/ ( u1 u2 -- u ) 0 SWAP UM/MOD NIP ;

: EXTEND ( n -- d ) DUP 0< ;

: M/MOD ( d n -- nm nq ) \ floored
  EXTEND  DUP >R  IF NEGATE >R DNEGATE R> THEN
  >R DUP 0< IF R@ + THEN  R> UM/MOD
  R> IF SWAP NEGATE SWAP THEN ;

: /MOD ( n n -- nm nq ) SWAP EXTEND ROT M/MOD ;
: MOD ( n n -- n ) /MOD DROP ;
: / ( n n -- n ) /MOD NIP ;

: */MOD ( n n n -- r q ) >R M* R> M/MOD ;
: */ ( n n n -- q ) */MOD NIP ;

VARIABLE H
VARIABLE HLD
VARIABLE UP      [HEX] F380 ' UP !
VARIABLE BASE            10 ' BASE !
VARIABLE 'EMIT        ' TX! ' 'EMIT !
VARIABLE '?KEY        ' RX? ' '?KEY !
VARIABLE SPAN
VARIABLE >IN
VARIABLE BLK
VARIABLE #TIB
VARIABLE FENCE

  32 CONSTANT BL

   2 CONSTANT CELL

1024 CONSTANT B/BUF
  64 CONSTANT B/LINE

[HEX] F000 CONSTANT S0
[HEX] F000 CONSTANT TIB
[HEX] F380 CONSTANT R0

: HERE ( -- a ) H @ ;

: PAD ( -- a ) HERE B/LINE 2* + ;

: CELL+ ( n -- n ) CELL + ;

: CELL- ( n -- n ) CELL - ;

: CELLS ( n -- n ) 1 LSHIFT ( CELL * ) ;

: >CHAR ( n -- c )
  127 AND  DUP BL 127 WITHIN 0= IF DROP [CHAR] _ THEN ;

: DEPTH ( -- n ) SP@ S0 SWAP - 1 RSHIFT ( CELL / ) ;

: PICK ( u -- w ) 1+ CELLS SP@ + @ ;

: 2OVER ( d1 d2 -- d1 d2 d1 ) 3 PICK 3 PICK ;

: +! ( n a -- ) SWAP OVER @ + SWAP ! ;

: 2! ( d a -- ) SWAP OVER ! CELL+ ! ;
: 2@ ( a -- d ) DUP CELL+ @ SWAP @ ;

: ?0>DUP ( n -- 0 | n n ) DUP 0> IF DUP EXIT THEN DROP 0 ;

: @EXECUTE ( a -- ) @ ?DUP IF EXECUTE THEN ;

: EMIT ( c -- ) 'EMIT @EXECUTE ;

: ?KEY ( -- c T | F ) '?KEY @EXECUTE ;

: CONSOLE ( -- ) ['] TX! 'EMIT !  ['] RX? '?KEY ! ;

: KEY ( -- c ) BEGIN ?KEY UNTIL ;

: COUNT ( a -- a n ) DUP 1+ SWAP C@ ;

: TYPE ( a n -- ) ?0>DUP IF 0 DO COUNT EMIT LOOP THEN DROP ;

: CR ( -- ) 13 EMIT 10 EMIT ;

: BELL ( -- ) 7 EMIT ;

: BACKSPACE ( -- ) 8 DUP EMIT BL EMIT EMIT ;

: PAGE ( -- ) 50 0 DO CR LOOP ;

: SPACE ( -- ) BL EMIT ;

: SPACES ( n -- ) ?0>DUP IF 0 DO SPACE LOOP THEN ;

: HEX     ( -- ) 16 BASE ! ;
: DECIMAL ( -- ) 10 BASE ! ;
: BINARY  ( -- )  2 BASE ! ;

: DIGIT ( u -- c ) DUP 9 > IF 55 + EXIT THEN [CHAR] 0 + ;

: <# ( ud -- u ) DROP PAD HLD ! ;

: HOLD ( c -- ) -1 HLD +!  HLD @ C! ;

: # ( u -- u ) BASE @  0 SWAP UM/MOD  SWAP DIGIT HOLD ;

: #S ( u -- 0 ) BEGIN # DUP WHILE REPEAT ;

: SIGN ( n u -- u ) SWAP 0< IF [CHAR] - HOLD THEN ;

: #> ( u -- a u ) DROP HLD @ PAD OVER - ;

: (PAD) ( u1 u2 -- u1 )
  2DUP < IF OVER - SPACES EXIT THEN DROP ;

:  .  ( n -- )    DUP ABS 0 <# #S SIGN #>          TYPE SPACE ;
: U.  ( u -- )            0 <# #S      #>          TYPE SPACE ;
:  .R ( nu-- ) >R DUP ABS 0 <# #S SIGN #> R> (PAD) TYPE ;
: U.R ( uu-- ) >R         0 <# #S      #> R> (PAD) TYPE ;

: H. ( u -- ) BASE @ HEX SWAP U. BASE ! ;

: ? ( a -- ) @ . ;

VARIABLE TMP

: EXPECT ( a u -- ) DUP TMP !  BEGIN
    DUP 0= IF DROP BL SWAP C!  TMP @ SPAN ! EXIT THEN
    KEY DUP 13 = IF DROP  TMP @ SWAP - SPAN !
                    BL SWAP C!  SPACE EXIT           ELSE
        DUP  8 = OVER 127 = OR
                 IF DROP DUP TMP @ <> IF
                    SWAP 1- SWAP 1+ BACKSPACE THEN   ELSE
        DUP 24 = IF DROP 2DROP 0 SPAN ! EXIT         ELSE
        DUP BL 127 WITHIN IF DUP EMIT
                 SWAP >R OVER C! R>  1- SWAP 1+ SWAP ELSE
    DROP BELL THEN THEN THEN THEN  AGAIN ;

: QUERY ( -- )
  TIB 80 EXPECT  SPAN @ #TIB !  0 >IN !  0 BLK ! ;

[HEX] F400 CONSTANT B0ADDR
[HEX] F800 CONSTANT B1ADDR

VARIABLE ACTIVE   -1 ' ACTIVE !
VARIABLE B0BLK    -1 ' B0BLK !
VARIABLE B1BLK    -1 ' B1BLK !
VARIABLE B0UPD     0 ' B0UPD !
VARIABLE B1UPD     0 ' B1UPD !

: ACTIVATE ( u -- ) B0BLK @ = 0= ACTIVE ! ;

: FIND-BLOCK ( u -- a T | 0 )
  DUP B0BLK @ = IF DROP B0ADDR -1 EXIT THEN
      B1BLK @ = IF      B1ADDR -1 EXIT THEN 0 ;

: SOURCE ( -- a )
  BLK @ ?DUP IF FIND-BLOCK DROP EXIT THEN TIB ;

: EXTRACT ( -- c ) SOURCE >IN @ + C@ ;

: ?MORE ( -- f ) >IN @ #TIB @ < ;

: WORD ( c -- a ) TMP !  HERE 1+
  BEGIN ?MORE EXTRACT TMP @ = AND WHILE
    1 >IN +! REPEAT
  BEGIN ?MORE EXTRACT TMP @ <> AND WHILE
    EXTRACT OVER C! 1+  1 >IN +!  REPEAT
  EXTRACT OVER C!  1 >IN +!  HERE 1+ - HERE C!  HERE ;

: .S ( -- ) S0 SP@ CELL+ = IF EXIT THEN
  S0 SP@ CELL+ DO I @ . CELL /LOOP ;

: CMOVE ( a a n -- ) ?0>DUP IF
    0 DO >R COUNT R@ C! R> 1+ LOOP 2DROP  THEN ;

: <CMOVE ( a a n -- ) ?0>DUP IF >R SWAP R@ + 1- SWAP R@ + 1- R>
    0 DO >R COUNT R@ C! 2 - R> 1- LOOP 2DROP  THEN ;

: MOVE ( a a n -- ) CELLS CMOVE ;

: UNLOOP ( -- ) R> R> R> 2DROP >R ;

: -TRAILING ( a n -- a n ) ?0>DUP IF
  1 SWAP 1- NEGATE DO DUP I - C@
      BL XOR IF I 1- NEGATE UNLOOP EXIT THEN
      LOOP 0 THEN ;

: -TEXT ( a1 u a2 -- n )
  SWAP DUP 0= IF 2DROP DROP 0 EXIT THEN
  0 DO OVER C@ OVER C@ - DUP IF
      -ROT 2DROP UNLOOP EXIT THEN
    DROP 1+ SWAP 1+ SWAP LOOP 2DROP 0 ;

: FILL ( a n c -- ) OVER 0> IF
    -ROT 0 DO 2DUP C! 1+ LOOP ELSE
    DROP THEN  2DROP ;

: ERASE ( a n -- ) 0 FILL ;

: BLANK ( a n -- ) BL FILL ;

: ?DIGIT ( c -- u T | F )
  DUP 64 > IF 55 - ELSE
  DUP 47 > IF 48 - THEN THEN
  DUP BASE @ U< IF -1 EXIT THEN DROP 0 ;

: CONVERT ( u a -- u a ) 1+
  BEGIN DUP C@ ?DIGIT WHILE ( u a digit )
    ROT BASE @ * + SWAP 1+ REPEAT ;

VARIABLE LAST
VARIABLE CONTEXT
VARIABLE CURRENT
VARIABLE (FORTH)

: FORTH ( -- ) (FORTH) CONTEXT ! ;

: DEFINITIONS ( -- ) CONTEXT @ CURRENT ! ;

: >NFA ( a -- a ) 10 - ;
: >LFA ( a -- a )  6 + ;
: >CFA ( a -- a )  8 + ;
: >PFA ( a -- a ) 10 + ;

: LOOKUP ( a a -- a f )
  BEGIN ?DUP WHILE
    2DUP ?SAME IF NIP -1 EXIT THEN
    >LFA @ REPEAT 0 ;

: UPCASE ( a -- ) COUNT 0 DO
    COUNT DUP [CHAR] a [CHAR] { WITHIN IF BL - THEN
    OVER 1- C! LOOP DROP ;

: ?FIND ( a -- a f ) DUP UPCASE
  CONTEXT @ @ LOOKUP IF >PFA -1 EXIT THEN
  (FORTH) CONTEXT @ = IF 0 EXIT THEN
  (FORTH) @ LOOKUP IF >PFA -1 EXIT THEN  0 ;

: FIND ( -- a ) BL WORD ?FIND IF >NFA >CFA EXIT THEN DROP 0 ;

: ?NUMBER ( a -- n T | F )
  DUP 1+ C@ [CHAR] - = DUP >R IF 1+ THEN
  0 SWAP CONVERT  C@ BL = IF -1 ELSE DROP 0 THEN
  R> OVER AND IF SWAP NEGATE SWAP THEN ;

VARIABLE STATE 0 ' STATE !

DEFER QUIT

: ABORT ( -- ) S0 SP!  0 STATE !  QUIT ;

: ?WHAT ( a -- ) COUNT TYPE [CHAR] ? EMIT CR ABORT ;

: $+ ( a1 -- a1 a2 ) DUP DUP C@ + 1+ ;

: ($") ( -- a ) R> $+ >R ; COMPILE-ONLY

: ?STACK ( -- ) SP@ S0 U>  SP@ PAD B/BUF + U< OR
  IF $" STK ERR" ?WHAT THEN ;

:  ( ( -- ) [CHAR] ) WORD DROP ; IMMEDIATE
: .( ( -- ) [CHAR] ) WORD COUNT TYPE ; IMMEDIATE
:  \ ( -- ) BLK @ 0= IF #TIB @ >IN ! EXIT THEN
   >IN @ B/LINE + 1- DUP B/LINE MOD - >IN ! ; IMMEDIATE

: ?ENOUGH ( -- ) [CHAR] : EMIT KEY BACKSPACE [CHAR] q = ;

: WORDS ( -- ) 0 TMP !  CR  CONTEXT @ @ BEGIN ?DUP WHILE
    DUP COUNT [HEX] 1F AND 5 MIN DUP >R TYPE 8 R> - SPACES
    1 TMP +!  TMP @ 199 > IF
      0 TMP ! ?ENOUGH IF DROP EXIT THEN THEN  >LFA @ REPEAT ;

: ?COMPILE-ONLY ( a -- a ) DUP >NFA C@ [HEX] 40 AND IF
    $" COMP ONLY" ?WHAT THEN ;

: ?IMMEDIATE ( a -- a w ) DUP >NFA C@ [HEX] 80 AND ;

:  , ( w -- ) H @  ! CELL H +! ;
: C, ( c -- ) H @ C!    1 H +! ;

: ' ( -- a ) BL WORD ?FIND 0= IF ?WHAT THEN ;

: COMPILE ( -- ) R> DUP @ , CELL+ >R ; COMPILE-ONLY

: LITERAL ( w -- ) COMPILE (LIT) , ; IMMEDIATE COMPILE-ONLY

: DUMP ( a -- ) BASE @ >R HEX
    DUP 16 0 DO COUNT 0 <# # # #> TYPE SPACE LOOP
  DROP  16 0 DO COUNT >CHAR EMIT LOOP  R> BASE ! SPACE ;

: HD ( a n -- ) BASE @ >R HEX
  0 DO CR DUP 0 <# # # # # #> TYPE
    SPACE DUMP LOOP  R> BASE ! ;

: PFA>CFA ( a -- a ) CELL- ;
: CFA>PFA ( a -- a ) CELL+ ;

: NUMBER ( a -- n )
  DUP ?NUMBER IF NIP EXIT THEN ?WHAT ;

VARIABLE DBL
VARIABLE 'NUMBER  ' NUMBER ' 'NUMBER !

: NUMBER 'NUMBER @EXECUTE ;

: DLITERAL ( d -- )
  SWAP [COMPILE] LITERAL [COMPILE] LITERAL ;
  IMMEDIATE COMPILE-ONLY

: INTERPRET ( -- ) BEGIN BL WORD DUP C@ WHILE
    STATE @ IF  ?FIND IF
        ?IMMEDIATE IF EXECUTE ELSE PFA>CFA , THEN ELSE
        NUMBER DBL @ IF
          [COMPILE] DLITERAL ELSE
          [COMPILE] LITERAL  THEN THEN
    ELSE ?FIND IF
        ?COMPILE-ONLY EXECUTE ELSE
        NUMBER THEN
    THEN ?STACK REPEAT DROP ;

: .OK ( -- )
  STATE @ 0= IF [CHAR] O EMIT [CHAR] K EMIT THEN CR ;

: ['] ( -- a ) ' [COMPILE] LITERAL ; IMMEDIATE COMPILE-ONLY

: [HEX] ( -- w ) BASE @ >R  BL WORD DUP UPCASE
  DUP HEX ?NUMBER 0= IF R> BASE ! ?WHAT THEN  NIP
  R> BASE !  STATE @ IF [COMPILE] LITERAL THEN ; IMMEDIATE

: [CHAR] ( -- c ) BL WORD 1+ C@
  STATE @ IF [COMPILE] LITERAL THEN ; IMMEDIATE

: [COMPILE] ( -- ) ' PFA>CFA , ; IMMEDIATE COMPILE-ONLY

: ALLOT ( n -- ) HERE + H ! ;

: ENTRY ( a -- ) DUP UPCASE
  COUNT 5 SWAP DO DUP I + BL SWAP C! LOOP DROP ;

: CREATE ( -- ) BL WORD ENTRY  6 ALLOT
  CURRENT @ @ ,  ['] (VAR) ,  HERE >NFA LAST ! ;

: PERFORMS ( -- ) R>  DUP @ CFA>PFA LAST @ >CFA !
  CELL+ >R ; COMPILE-ONLY

: LINK ( -- ) LAST @ CURRENT @ ! ;

: VARIABLE ( -- ) CREATE 0 , LINK ;

: CONSTANT ( w -- ) CREATE , PERFORMS (CONST) LINK ;

: [ ( -- )  0 STATE ! ; IMMEDIATE
: ] ( -- ) -1 STATE ! ;

: : ( -- ) CREATE PERFORMS (COLON) ] ;
: ; ( -- ) COMPILE EXIT [COMPILE] [ LINK ; IMMEDIATE
           COMPILE-ONLY

: (DEFER) ( -- ) $" DEFER ERR" ?WHAT ; COMPILE-ONLY

: DEFER ( -- ) CREATE PERFORMS (COLON) COMPILE (DEFER)
  COMPILE EXIT LINK ;

: IS ( -- ) LAST @ >CFA ' ! ;

: MARK ( -- a ) HERE 0 , ; COMPILE-ONLY

: RESOLVE ( a -- ) HERE SWAP ! ; COMPILE-ONLY

: IF ( f -- ) COMPILE (0BRANCH) MARK ; IMMEDIATE COMPILE-ONLY
: ELSE ( -- ) COMPILE (BRANCH) MARK SWAP RESOLVE ; IMMEDIATE
              COMPILE-ONLY
: THEN ( -- ) RESOLVE ; IMMEDIATE COMPILE-ONLY

: DO ( n n -- ) COMPILE (DO) HERE ; IMMEDIATE COMPILE-ONLY
: LOOP ( -- ) COMPILE (LOOP) , ; IMMEDIATE COMPILE-ONLY
: +LOOP ( n -- ) COMPILE (+LOOP) , ; IMMEDIATE COMPILE-ONLY
: /LOOP ( u -- ) COMPILE (/LOOP) , ; IMMEDIATE COMPILE-ONLY
: LEAVE ( -- ) R> R> R> DROP DUP >R >R >R ; COMPILE-ONLY

: BEGIN ( -- ) HERE ; IMMEDIATE COMPILE-ONLY
: WHILE ( f -- ) [COMPILE] IF ; IMMEDIATE COMPILE-ONLY
: REPEAT ( -- ) COMPILE (BRANCH) SWAP , RESOLVE ; IMMEDIATE
                COMPILE-ONLY
: AGAIN ( f -- ) COMPILE (BRANCH) , ; IMMEDIATE COMPILE-ONLY
: UNTIL ( f -- ) COMPILE (0BRANCH) , ; IMMEDIATE COMPILE-ONLY

: IMMEDIATE    ( -- ) LAST @ C@ [HEX] 80 OR LAST @ C! ;
: COMPILE-ONLY ( -- ) LAST @ C@ [HEX] 40 OR LAST @ C! ;

: RECURSE ( -- ) LAST @ >CFA , ; IMMEDIATE COMPILE-ONLY

: I' ( -- w )    R> R> R@ -ROT >R >R ;
: J  ( -- w ) R> R> R> R@ -ROT >R >R SWAP >R ;

: $, ( -- ) [CHAR] " WORD C@ 1+ ALLOT ; COMPILE-ONLY

: $" ( -- a ) COMPILE ($") $, ; IMMEDIATE COMPILE-ONLY

: (.") ( -- ) R> $+ >R COUNT TYPE ; COMPILE-ONLY

: ." ( -- ) COMPILE (.") $, ; IMMEDIATE COMPILE-ONLY

: (ABORT") ( f -- ) R> $+ >R SWAP IF ?WHAT THEN DROP ;
           COMPILE-ONLY

: ABORT" ( f -- ) COMPILE (ABORT") $, ; IMMEDIATE
                  COMPILE-ONLY

: <BUILDS ( -- ) VARIABLE ; COMPILE-ONLY

: DOES> ( -- ) PERFORMS (DOES>) R> LAST @ >PFA ! ; COMPILE-ONLY

: ARRAY ( u -- ) <BUILDS CELLS ALLOT DOES> SWAP CELLS + ;

: USER ( u -- ) <BUILDS CELLS , DOES> @ UP @ + ;

: VOCABULARY ( -- ) <BUILDS 0 , DOES> CONTEXT ! ;

: EMPTY ( -- ) FORTH DEFINITIONS  FENCE @ DUP DUP
  CONTEXT @ !  CURRENT @ !  >PFA CELL+ H ! ;

: FORGET ( -- )
  CURRENT @ CONTEXT @ <>    ABORT" CURRENT"
  ' >NFA DUP  FENCE @ U> 0= ABORT" FENCE"
        DUP CONTEXT @ U> 0= ABORT" CONTEXT"
  DUP H !  >LFA @ CONTEXT @ ! ;

VARIABLE SCR

: EMPTY-BUFFERS ( -- ) -1 ACTIVE !
  0 DUP B0UPD ! B1UPD !  -1 DUP B0BLK ! B1BLK ! ;

: ?I/O ( f -- ) DUP 0= IF EMPTY-BUFFERS THEN
  0= ABORT" I/O ERR" ;

: ?EXIT-CACHED ( u -- a | u )
  DUP FIND-BLOCK IF SWAP ACTIVATE R> DROP THEN ;

: 0SAVE ( -- f )
  B0UPD @ IF B0ADDR B0BLK @ WRITE-BLOCK EXIT THEN -1 ;

: 1SAVE ( -- f )
  B1UPD @ IF B1ADDR B1BLK @ WRITE-BLOCK EXIT THEN -1 ;

: BUFFER ( u -- a ) ?EXIT-CACHED ACTIVE @ IF
    0SAVE ?I/O  B0BLK !  0 ACTIVE ! 0 B0UPD ! B0ADDR ELSE
    1SAVE ?I/O  B1BLK !  1 ACTIVE ! 0 B1UPD ! B1ADDR THEN ;

: BLOCK ( u -- a ) ?EXIT-CACHED
  DUP BUFFER DUP ROT READ-BLOCK ?I/O ;

: UPDATE ( -- ) ACTIVE @ 0< IF EXIT THEN
  -1 ACTIVE @ IF B1UPD ELSE B0UPD THEN ! ;

: WIPE ( -- ) ACTIVE @ 0< IF EXIT THEN
  ACTIVE @ IF B1ADDR ELSE B0ADDR THEN B/BUF BLANK ;

: COPY ( usrc udest -- ) SWAP BLOCK DROP
  ACTIVE @ IF B1BLK ELSE B0BLK THEN ! ;

: SAVE-BUFFERS ( -- )
  0SAVE 1SAVE AND ?I/O  0 DUP B0UPD ! B1UPD ! ;

: FLUSH ( -- ) SAVE-BUFFERS ;

: LIST ( u -- ) DUP SCR !  BLOCK  16 0 DO CR
    I 1+ 2 .R [CHAR] : EMIT SPACE
    DUP I B/LINE * + B/LINE TYPE  [CHAR] : EMIT
  LOOP DROP SPACE ;

: LOAD ( u -- )
  BLK @ >R  >IN @ >R  #TIB @ >R  ACTIVE @ >R
  DUP BLOCK DROP BLK !  B/BUF #TIB !  0 >IN !  INTERPRET
  R> ACTIVE !  R> #TIB !  R> >IN !  R> BLK ! ;

: THRU ( u1 u2 -- ) 1+ SWAP DO I . I LOAD LOOP ;

: INDEX ( n1 n2 -- ) 0 -ROT
  1+ SWAP DO CR I 0 .R [CHAR] : EMIT SPACE
    I BLOCK B/LINE TYPE  1+ DUP 20 > IF
      ?ENOUGH IF UNLOOP DROP EXIT THEN
      DROP 0 THEN
    LOOP DROP ;

: RESET ( -- ) FORTH DEFINITIONS
  EMPTY-BUFFERS  DECIMAL  [HEX] F380 UP !
  $" T3XFORTH" COUNT TYPE CR  ABORT ;

: (QUIT) ( -- )
  BEGIN R0 RP!  CONSOLE  QUERY INTERPRET .OK AGAIN ;
  IS QUIT  COMPILE-ONLY

: (FENCE) ;
' (FENCE) >NFA ' FENCE !

