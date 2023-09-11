\ T3XFORTH Decompiler (SEE)
\ Nils M Holm, 2021
\ In the public domain / under the CC0 license

\ This is a simple decompiler for T3XFORTH words. It is small,
\ reasonably fast, reconstructs control flow words, and gets
\ 99% of the cases right. The only exception I can think of is
\     BEGIN IF BEGIN AGAIN THEN AGAIN
\ which will erroneously decompile to
\     BEGIN WHILE BEGIN AGAIN REPEAT
\ because AGAIN THEN inside of BEGIN looks like REPEAT to the
\ decompiler. Note that the outer BEGIN is necessary to trigger
\ the error. Without it the code decompiles correctly.

VOCABULARY DECOMPILER  DECOMPILER DEFINITIONS

VARIABLE START  VARIABLE END

\ Control flow stack.
\ If you use more than 10 nested control constructs
\ in a word, you deserve the stack overflow.
10 ARRAY STACK  VARIABLE SP
: PUSH ( w a -- ) SP @ STACK !  1 SP +! ;
: POP  ( -- ) -1 SP +! ;
: MODI ( w a -- ) POP PUSH ;
: KIND ( -- w ) SP @ 0= IF 0 EXIT THEN  SP @ 1- STACK @ ;

\ Given PFA, find end of word, leave PFA on stack.
\ Does not work for last words in vocabularies or for
\ words not in CONTEXT. Fix me!
: FIND-END ( a -- a a ) >R  CONTEXT @ @ BEGIN
    DUP >LFA @ R@ >NFA = IF R> DROP CELL- EXIT THEN
    >LFA @ DUP 0= UNTIL  R> 2DROP  DUP 1024 + ;

\ Identify inlined operators
: =BRANCH   ( a -- f ) @ ['] (BRANCH)  PFA>CFA = ;
: =0BRANCH  ( a -- f ) @ ['] (0BRANCH) PFA>CFA = ;
: =LIT      ( a -- f ) @ ['] (LIT)     PFA>CFA = ;
: =DO       ( a -- f ) @ ['] (DO)      PFA>CFA = ;
: =LOOP     ( a -- f ) @ ['] (LOOP)    PFA>CFA = ;
: =+LOOP    ( a -- f ) @ ['] (+LOOP)   PFA>CFA = ;
: =/LOOP    ( a -- f ) @ ['] (/LOOP)   PFA>CFA = ;
: =$"       ( a -- f ) @ ['] ($")      PFA>CFA = ;
: =."       ( a -- f ) @ ['] (.")      PFA>CFA = ;
: =ABORT"   ( a -- f ) @ ['] (ABORT")  PFA>CFA = ;
: =COMPILE  ( a -- f ) @ ['] COMPILE   PFA>CFA = ;
: =PERFORMS ( a -- f ) @ ['] PERFORMS  PFA>CFA = ;

\ Skip over inline packed strings
: SKIP$ ( a -- a ) CELL+ DUP C@ + 1+ CELL- ;

VARIABLE NBR  \ Number of branches
\ Array for branch addresses
: BRANCHES ( n -- a ) CELLS PAD + ;

\ Find branch instructions in the program,
\ store addresses of their operands at PAD
: CACHE-BRANCHES ( -- ) 0 NBR !  END @ START @
  BEGIN 2DUP U> WHILE  DUP =BRANCH OVER =0BRANCH OR IF
      CELL+ DUP NBR @ BRANCHES !  1 NBR +!  THEN
    DUP  =LIT      OVER =DO    OR OVER =PERFORMS OR 
    OVER =+LOOP OR OVER =/LOOP OR OVER =COMPILE  OR
    OVER =LOOP  OR   IF CELL+ THEN
    DUP =$" OVER =." OR OVER =ABORT" OR IF SKIP$ THEN
    CELL+ REPEAT  2DROP ;

\ If some branch between A0 and AN points to A, return
\ the address of the inline operand of the branch
\ instruction, else return 0
: FIND-BRANCH ( a a0 an -- a a|0 ) CELL+ SWAP CELL+ SWAP
  NBR @ 0 DO  2DUP I BRANCHES @ -ROT WITHIN IF
      2 PICK I BRANCHES @ @ = IF 
        2DROP I BRANCHES @  UNLOOP EXIT THEN THEN
    LOOP 2DROP 0 ;

\ If something branches backward here, open BEGIN
: ?BEGIN ( a -- a ) DUP BEGIN END @ FIND-BRANCH ?DUP WHILE
    ." BEGIN " ['] BEGIN PUSH REPEAT ;

\ If something branches forward here and IF or ELSE is open,
\ close it; ELSE is only closed if the branch is unconditional
: ?THEN ( a -- a ) START @  BEGIN OVER FIND-BRANCH ?DUP WHILE
    KIND ['] IF = IF ." THEN " POP ELSE
    DUP CELL- =BRANCH KIND ['] ELSE = AND IF
      ." THEN " POP                THEN THEN  REPEAT ;

\ Is the branch at A a forward branch?
: ?FORWARD ( a -- a f ) DUP CELL+ @ OVER U> ;

\ Forward branch is always ELSE.
\ Backward branch is REPEAT in WHILE, else AGAIN (close both).
: .BRANCH ( a -- a ) ?FORWARD IF
    ." ELSE " ['] ELSE MODI                  ELSE
    KIND ['] WHILE = IF ." REPEAT " ELSE
                        ." AGAIN "  THEN POP THEN ;

\ Conditional forward branch to backward branch in BEGIN is
\ WHILE. Others are IF. Conditional backward branch is always
\ UNTIL (close it).
: .0BRANCH ( a -- a ) ?FORWARD IF
    DUP CELL+ @ CELL- CELL- DUP =BRANCH
    SWAP ?FORWARD NIP NOT AND
    KIND ['] BEGIN =      AND IF
      ." WHILE " ['] WHILE MODI ELSE
      ." IF "    ['] IF PUSH    THEN ELSE
    ." UNTIL " POP                   THEN ;

\ Given CFA print identifier name and
\ add trailing _'s for proper length
: .NAME ( a -- a ) CFA>PFA >NFA COUNT 31 AND DUP >R 5 MIN TYPE
  R> DUP 5 > IF DUP 5 DO [CHAR] _ EMIT LOOP THEN  DROP  SPACE ;

\ Print identifier at CFA A, if identified word is immediate,
\ prefix with [COMPILE]
: .IDENT ( a -- a ) DUP @ DUP CFA>PFA >NFA C@ 128 AND IF
    ." [COMPILE] " THEN  .NAME ;

\ If current word is COMPILE or PERFORMS, print and
\ skip over its operand
: .OPER ( a -- a ) DUP =COMPILE OVER =PERFORMS OR IF
    CELL+ .IDENT THEN ;

\ Emit and skip over packed string
: EMIT$ ( a -- a ) [CHAR] " EMIT SPACE DUP CELL+ COUNT TYPE
  [CHAR] " EMIT SPACE  SKIP$ ;

\ Print word flags
: .FLAGS ( a -- )
   START @ >NFA C@ 128 AND IF ." IMMEDIATE " THEN
   START @ >NFA C@  64 AND IF ." COMPILE-ONLY " THEN ;

\ Unconditional exit marks the end of a word (in case FIND-END
\ failed). A spurious EXIT will be emitted in this case.
: ?EXIT ( a -- a ) DUP CELL- =COMPILE IF EXIT THEN
  DUP @ ['] EXIT PFA>CFA = SP @ 0= AND IF
    DUP END ! THEN ;

\ Print head of colon definition
: .HEAD ( -- )   ." : "  HERE COUNT TYPE  SPACE ;

\ Print header, init variables
: SETUP ( a -- a ) DUP START !  DUP FIND-END END !  0 SP !
  CACHE-BRANCHES ;

\ Decompile colon definition at PFA A
: :SEE ( a -- ) SETUP  BEGIN DUP END @ U< WHILE  ?THEN ?BEGIN
    DUP =LIT     IF CELL+ DUP ?       ELSE
    DUP =BRANCH  IF .BRANCH     CELL+ ELSE
    DUP =0BRANCH IF .0BRANCH    CELL+ ELSE
    DUP =DO      IF ." DO "           ELSE
    DUP =LOOP    IF ." LOOP "   CELL+ ELSE
    DUP =+LOOP   IF ." +LOOP "  CELL+ ELSE
    DUP =/LOOP   IF ." /LOOP "  CELL+ ELSE
    DUP =$"      IF ." $"       EMIT$ ELSE
    DUP =."      IF ." ."       EMIT$ ELSE
    DUP =ABORT"  IF ." ABORT"   EMIT$ ELSE  .IDENT .OPER
    THEN THEN THEN THEN THEN THEN THEN THEN THEN THEN
    ?EXIT  CELL+ REPEAT  ?THEN  DROP  ." ; " ;

FORTH DEFINITIONS

\ Decompiler
DECOMPILER : SEE ( -- ) ' CR PFA>CFA
  DUP @ OVER CFA>PFA = IF ." \ CODE " DROP    ELSE
  DUP @ ['] (VAR)    = IF ." VARIABLE " .NAME ELSE
  DUP @ ['] (CONST)  = IF DUP CFA>PFA EXECUTE .
                          ." CONSTANT " .NAME ELSE
  DUP @ ['] (DOES>)  = IF ." \ DOES> "
                          CFA>PFA @ :SEE      ELSE
    CFA>PFA .HEAD :SEE .FLAGS
  THEN THEN THEN THEN ;  FORTH
