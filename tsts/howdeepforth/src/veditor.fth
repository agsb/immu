\ T3XFORTH Screen Editor
\ Nils M Holm, 2021
\ In the public domain / CC0 Licence

VOCABULARY VEDITOR  VEDITOR DEFINITIONS

\ A simple, vi-like screen editor. Needs a VT-100-compatible
\ terminal. Xterm or ANSI.SYS work fine. See below screen for
\ commands. The page can also be fetched by typing :h while
\ editing.

\ --------------------------------------------------------------
\ hjkl  left/down/up/right  dw   del word      yw  yank word
\ w b   next/prev word      dd   del line      yy  yank line
\ 0 $   first/last column   D    del to eol    Y   yank to eol
\ tC    move to char C      d'   del to mark   y'  yank to mark
\ < >   prev/next screen    dtC  del to char   ytC yank to char
\ ^L    redraw screen       p P  paste (left)  m   set mark
\             ^G which screen?    ^U toggle auto-upcase
\   i   insert text         ESC end input      :w write text   
\   A   append to line      R   replace text   :q quit
\ o O   open line (above)   J   join lines     ZZ write + exit
\ --------------------------------------------------------------
BLK @ CONSTANT HELP-SCR

VARIABLE TEXT
VARIABLE CX
VARIABLE CY
VARIABLE MARK
VARIABLE MODIFIED
VARIABLE AUTO-UPC

VARIABLE SAVEDXY CELL ALLOT

: ESC ( -- ) 27 EMIT ;

: SKIP-IF ( f c -- ) SWAP IF WORD THEN ;

FIND CURSOR [CHAR] @ SKIP-IF
: PAGE ( -- ) ESC ." [H" ESC ." [2J" ;
: CURSOR ( nx ny -- ) ESC [CHAR] [ EMIT
  1+ 0 .R [CHAR] ; EMIT 1+ 0 .R  [CHAR] H EMIT ;  @

: BOTTOM ( -- ) 0 16 CURSOR ;

: SYNCH ( -- ) CX @ CY @ CURSOR ;

: LINE  ( -- ) TEXT @ CY @ B/LINE * + ;
: POINT ( -- ) LINE CX @ + ;

: MARK-CHAR ( n -- )
  MARK @ = IF [CHAR] < ELSE [CHAR] : THEN ;

: DRAW ( a n -- ) 16 SWAP DO
    0 I CURSOR  DUP I B/LINE * + B/LINE TYPE
    I MARK-CHAR EMIT LOOP  DROP ;

: DRAW-MARK ( -- ) 16 0 DO
    B/LINE I CURSOR I MARK-CHAR EMIT LOOP ;

VARIABLE MSG  0 MSG !

: MESSAGE ( a -- ) BOTTOM COUNT TYPE  1 MSG ! ;

: CLEAR ( -- ) BOTTOM B/LINE SPACES  0 MSG ! ;

: STATUS ( -- ) BOTTOM SCR ? 1 MSG ! ;

: REDRAW ( -- ) TEXT @ 0 DRAW STATUS ;

: REDRAW-LINE ( -- ) 0 CY @ CURSOR LINE B/LINE TYPE ;

: SAVE-POS ( -- ) CX @ CY @ SAVEDXY 2! ;
: REST-POS ( -- ) SAVEDXY 2@ CY ! CX ! ;

: LOAD-TEXT ( n -- ) DUP SCR !  BLOCK TEXT ! ;
: SAVE-TEXT ( -- ) UPDATE SAVE-BUFFERS  0 MODIFIED ! ;

: LEFT  ( -- ) CX @ 1- 63 AND CX ! ; \ assumes B/LINE 64 =
: RIGHT ( -- ) CX @ 1+ 63 AND CX ! ; \ assumes B/LINE 64 =
: DOWN  ( -- ) CY @ 1+ 15 AND CY ! ; \ 16 lines / screen
: UP    ( -- ) CY @ 1- 15 AND CY ! ; \ 16 lines / screen

: T@ ( -- ) POINT C@ ;

: ISSPACE ( c -- f ) BL = ;

: ?LOOPED ( n -- ) CX @ = IF R> EXIT THEN ;

: WORD-RIGHT ( -- ) CX @
  BEGIN T@ ISSPACE NOT WHILE RIGHT DUP ?LOOPED REPEAT
  BEGIN T@ ISSPACE     WHILE RIGHT DUP ?LOOPED REPEAT DROP ;

: WORD-LEFT ( -- ) CX @  LEFT
  BEGIN T@ ISSPACE     WHILE LEFT DUP ?LOOPED REPEAT
  BEGIN T@ ISSPACE NOT WHILE LEFT DUP ?LOOPED REPEAT
  DROP  RIGHT ;

: END-OF-LINE ( -- ) LINE B/LINE -TRAILING NIP CX ! ;

: INS-CHAR ( c -- )
  POINT POINT 1+ B/LINE CX @ - 1- <CMOVE  POINT C! ;

: DEL-CHAR ( -- )
  POINT 1+ POINT B/LINE CX @ - 1- CMOVE
  BL LINE B/LINE + 1- C! ;

: SPACE-LEFT ( -- ) LINE B/LINE + 1- C@ BL = ;

: ?BLANK ( a n -- ) 0 DO DUP I + C@ BL = NOT IF
    UNLOOP DROP 0 EXIT THEN LOOP  DROP 1 ;

: DEL-RANGE ( n -- )
  >R  POINT R@ +  POINT  B/LINE CX @ - R@ -  CMOVE
  LINE B/LINE + R@ - R> BLANK  1 MODIFIED ! ;

: INS-LINE-HERE ( -- f )
  TEXT @ B/BUF + B/LINE - B/LINE ?BLANK NOT IF BELL 0 EXIT THEN
  POINT  POINT B/LINE +  B/BUF CY @ 1+ B/LINE * - <CMOVE
  POINT B/LINE BLANK 1 ;

: SPLIT ( -- ) INS-LINE-HERE IF
    DOWN  CX @  0 CX !  DEL-RANGE
    TEXT @ CY @ 1- DRAW  THEN ;

: TOGGLE-AUC ( -- ) AUTO-UPC @ NOT AUTO-UPC ! ;

: SYNCH-KEY ( -- ) SYNCH KEY MSG @ IF CLEAR THEN
  DUP 21 = IF TOGGLE-AUC THEN ;

: AUTO-UPCASE ( c -- c ) AUTO-UPC @ IF
    DUP [CHAR] a [CHAR] z 1+ WITHIN IF 32 - THEN THEN ;

: INPUT ( -- ) 1 MODIFIED !  BEGIN SYNCH-KEY AUTO-UPCASE
    DUP 27 = IF DROP LEFT EXIT                 ELSE
    DUP  8 = CX @ 0> AND IF
                DROP LEFT DEL-CHAR REDRAW-LINE ELSE
    DUP 13 = IF DROP SPLIT                     ELSE
    DUP 32 127 WITHIN SPACE-LEFT AND IF
                INS-CHAR REDRAW-LINE RIGHT     ELSE
                DROP BELL
             THEN THEN THEN THEN  AGAIN ;

: OPEN-LINE ( -- )
  0 CX ! INS-LINE-HERE IF TEXT @ CY @ DRAW  INPUT THEN ;

: YANKED ( -- a ) PAD ;

VARIABLE #YANKED 
VARIABLE LINEMODE

: SET-MARK ( -- ) CY @ MARK ! DRAW-MARK ;

: C-YANK ( n -- )
  DUP #YANKED !  POINT YANKED ROT CMOVE  0 LINEMODE ! ;

: TRIM-YANKED ( -- )
  PAD #YANKED @ -TRAILING #YANKED ! DROP ;

: YANK-TO-EOL ( -- ) B/LINE CX @ - C-YANK TRIM-YANKED ;

: C-DELETE ( n -- ) DUP C-YANK DEL-RANGE ;

: DEL-TO-EOL ( -- ) CX @ B/LINE 1- = NOT IF
    B/LINE 1- CX @ - C-DELETE TRIM-YANKED
    REDRAW-LINE THEN ;

: DEL-WORD ( -- ) SAVE-POS WORD-RIGHT POINT REST-POS
  POINT - DUP 0> IF C-DELETE REDRAW-LINE ELSE
                    DROP DEL-TO-EOL      THEN ;

: FIND-CHAR ( -- ) CX @  SYNCH-KEY
  BEGIN DUP T@ <> CX @ B/LINE < AND WHILE 1 CX +! REPEAT
  T@ = IF DROP EXIT THEN  BELL CX !  ;

: DEL-TO ( -- ) SAVE-POS FIND-CHAR POINT REST-POS
  POINT - DUP 0> IF C-DELETE REDRAW-LINE ELSE DROP THEN ;

: EXCHANGE ( a a -- ) 2DUP @ >R @ SWAP ! R> SWAP ! ;

: BLOCK-SIZE ( -- u ) MARK @ 1+ CY @ - B/LINE * ;

: YANK-LINES ( -- ) 
  CY @ MARK @ > IF CY MARK EXCHANGE DRAW-MARK THEN
  TEXT @ CY @ B/LINE * +  YANKED  BLOCK-SIZE  CMOVE
  BLOCK-SIZE #YANKED !  1 LINEMODE ! ;

: DEL-LINES ( -- ) YANK-LINES
  MARK @ 1+ B/LINE * TEXT @ +
    CY @    B/LINE * TEXT @ +
  B/BUF CY @ 1+ B/LINE * -     CMOVE
  TEXT @ B/BUF + BLOCK-SIZE -  BLOCK-SIZE  BLANK
  REDRAW  1 MODIFIED ! ;

: DEL-THIS-LINE ( -- ) SET-MARK DEL-LINES ;

: DELETE-MODE ( -- )
  KEY DUP [CHAR] w = IF DROP DEL-WORD      ELSE
      DUP [CHAR] d = IF DROP DEL-THIS-LINE ELSE
      DUP [CHAR] t = IF DROP DEL-TO        ELSE
      DUP [CHAR] ' = IF DROP DEL-LINES     ELSE
                        BELL
                     THEN THEN THEN THEN ;

: YANK-WORD ( -- ) SAVE-POS WORD-RIGHT POINT REST-POS
  POINT - DUP 0> IF C-YANK           ELSE
                    DROP YANK-TO-EOL THEN ;

: YANK-TO ( -- ) SAVE-POS FIND-CHAR POINT REST-POS
  POINT - DUP 0> IF C-YANK ELSE DROP THEN ;

: YANK-THIS-LINE ( -- ) SET-MARK YANK-LINES ;

: YANK-MODE ( -- )
  KEY DUP [CHAR] w = IF DROP YANK-WORD      ELSE
      DUP [CHAR] y = IF DROP YANK-THIS-LINE ELSE
      DUP [CHAR] t = IF DROP YANK-TO        ELSE
      DUP [CHAR] ' = IF DROP YANK-LINES     ELSE
                        BELL
                     THEN THEN THEN THEN ;

: INS-BLANKS ( n -- )
  POINT  POINT #YANKED @ + 
  B/LINE CX @ - #YANKED @ - <CMOVE
  POINT #YANKED @ BLANK ;

: C-PASTE ( -- )
  LINE B/LINE + #YANKED @ - #YANKED @ ?BLANK 0= IF
    BELL EXIT THEN
  INS-BLANKS  PAD POINT #YANKED @ CMOVE  REDRAW-LINE ;

: INSERT-LINES ( n -- ) 0 CX !
  POINT  POINT #YANKED @ +
  B/BUF CY @ B/LINE * - #YANKED @ - <CMOVE
  POINT #YANKED @ BLANK ;

: L-PASTE ( -- )
  TEXT @ B/BUF + #YANKED @ - #YANKED @ ?BLANK 0= IF
    BELL EXIT THEN
  INSERT-LINES  PAD POINT #YANKED @ CMOVE
  TEXT @ CY @ DRAW ;

: PASTE ( -- ) #YANKED @ 0= IF EXIT THEN  1 MODIFIED !
  LINEMODE @ IF L-PASTE EXIT THEN C-PASTE ;

: ADJUST ( -- ) LINEMODE @ IF DOWN EXIT THEN RIGHT ;

: ?DISCARD ( -- ) MODIFIED @ 0= IF EXIT THEN
  $" DISCARD (y/N)" MESSAGE
  KEY CLEAR [CHAR] y = NOT IF R> EXIT THEN
  EMPTY-BUFFERS  0 MODIFIED ! ;

: HELP ( -- ) PAD B/BUF + HELP-SCR READ-BLOCK IF
    PAD B/BUF + 0 DRAW  KEY DROP REDRAW THEN ;

: COLON-COMMAND ( -- ) BOTTOM [CHAR] : EMIT
  KEY DUP [CHAR] q = IF DROP ?DISCARD .OK QUIT ELSE
      DUP [CHAR] w = IF DROP SAVE-TEXT
                             $" SAVED" MESSAGE ELSE
      DUP [CHAR] h = IF DROP HELP              ELSE
                        DROP BELL
                     THEN THEN THEN ;

: LENGTH ( a -- ) B/LINE -TRAILING NIP ;

: JOIN-LINES ( -- ) CY @ 15 = IF BELL EXIT THEN
  CX @ LINE B/LINE + LENGTH + B/LINE > IF BELL EXIT THEN
  LINE LENGTH CX @ > IF BELL EXIT THEN
  LINE B/LINE + B/LINE -TRAILING  LINE CX @ +  SWAP CMOVE
  1 MODIFIED !  REDRAW-LINE  DOWN DEL-THIS-LINE UP ;

: REPLACE ( -- ) 1 MODIFIED !  BEGIN SYNCH-KEY AUTO-UPCASE
             DUP 27 = IF DROP LEFT EXIT          ELSE
    DUP 32 127 WITHIN IF DUP EMIT POINT C! RIGHT ELSE
                         DROP BELL
                      THEN THEN  AGAIN ;

: FORWARD ( -- ) ?DISCARD SCR @ 1+ LOAD-TEXT REDRAW ;

: BACKWARD ( -- ) ?DISCARD SCR @ 1- LOAD-TEXT REDRAW ;

: 6VEDIT ( -- )
    DUP [CHAR] < = IF DROP BACKWARD       ELSE
    DUP [CHAR] f = IF DROP FIND-CHAR      ELSE
    DUP        7 = IF DROP STATUS         ELSE
    DUP [CHAR] D = IF DROP DEL-TO-EOL     ELSE
    DUP [CHAR] Y = IF DROP YANK-TO-EOL    ELSE
                      DROP $" :H = HELP" MESSAGE
                   THEN THEN THEN THEN THEN ;

: 5VEDIT ( -- )
    DUP [CHAR] J = IF DROP JOIN-LINES     ELSE
    DUP [CHAR] R = IF DROP REPLACE        ELSE
    DUP [CHAR] O = IF DROP OPEN-LINE      ELSE
    DUP [CHAR] o = IF DROP DOWN OPEN-LINE ELSE
    DUP [CHAR] > = IF DROP FORWARD        ELSE
                      6VEDIT
                   THEN THEN THEN THEN THEN ;

: 4VEDIT ( -- )
    DUP [CHAR] m = IF DROP SET-MARK      ELSE
    DUP [CHAR] y = IF DROP YANK-MODE     ELSE
    DUP [CHAR] p = IF DROP ADJUST PASTE  ELSE
    DUP [CHAR] P = IF DROP PASTE         ELSE
    DUP [CHAR] : = IF DROP COLON-COMMAND ELSE
                      5VEDIT
                   THEN THEN THEN THEN THEN ;

: 3VEDIT ( -- )
    DUP [CHAR] A = IF DROP END-OF-LINE INPUT    ELSE
    DUP [CHAR] x = IF DROP DEL-CHAR REDRAW-LINE ELSE
    DUP [CHAR] X = IF DROP LEFT DELETE-CHAR
                      REDRAW-LINE               ELSE
    DUP [CHAR] d = IF DROP DELETE-MODE          ELSE
    DUP [CHAR] $ = IF DROP END-OF-LINE          ELSE
                      4VEDIT
                   THEN THEN THEN THEN THEN ;

: 2VEDIT ( -- )
    DUP [CHAR] 0 = IF DROP 0 CX !      ELSE
    DUP [CHAR] w = IF DROP WORD-RIGHT  ELSE
    DUP [CHAR] b = IF DROP WORD-LEFT   ELSE
    DUP       12 = IF DROP PAGE REDRAW ELSE
    DUP [CHAR] i = IF DROP INPUT       ELSE
                      3VEDIT
                   THEN THEN THEN THEN THEN ;

: INIT ( -- ) 0 CX !  0 CY !  0 MODIFIED ! ;

: SAVE ( -- ) KEY [CHAR] Z = NOT IF EXIT THEN
  MODIFIED @ IF SAVE-TEXT THEN  BOTTOM ;

: VEDIT ( n -- ) INIT  LOAD-TEXT  PAGE  REDRAW
  BEGIN SYNCH-KEY
    DUP [CHAR] h = IF DROP LEFT      ELSE
    DUP [CHAR] j = IF DROP DOWN      ELSE
    DUP [CHAR] k = IF DROP UP        ELSE
    DUP [CHAR] l = IF DROP RIGHT     ELSE
    DUP [CHAR] Z = IF DROP SAVE EXIT ELSE
                      2VEDIT
                   THEN THEN THEN THEN THEN  AGAIN ;

FORTH DEFINITIONS

VEDITOR : VE ( n -- ) VEDIT ; FORTH

