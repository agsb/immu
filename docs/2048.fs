
\
\ https://gitlab.com/goblinrieur/2048
\
\ https://pastebin.com/4jJ0eec7

\ 2048 Game
\ Sliding squares game translated from XPL0 version.
\ This version adds score display and winning message.
\
\ Assumes ANSI colour terminal and 200x cursor keys
\ Tested on Gforth for Windows
 
also forth definitions decimal
 
: (U.)  0 <# #s #> ;
 
: GetKey ( -- u )  ekey ekey>fkey drop ;
 
\ Cursor hide/show
: -CURSOR ( -- )  .\" \x1b[?25l" ;  \ hide cursor
: +CURSOR ( -- )  .\" \x1b[?25h" ;  \ show cursor
 
: NORMAL ( -- )  .\" \x1b[0m" ;  \ reset attributes
: BRIGHT ( -- )  .\" \x1b[1m" ;
 
: BLACK   .\" \x1b[40m" ;
: RED     .\" \x1b[41m" ;
: GREEN   .\" \x1b[42m" ;
: YELLOW  .\" \x1b[43m" ;
: BLUE    .\" \x1b[44m" ;
: MAGENTA .\" \x1b[45m" ;
: CYAN    .\" \x1b[46m" ;
: WHITE   .\" \x1b[47m" ;
 
create BG
 ' black , ' blue , ' green , ' cyan ,
 ' red , ' magenta , ' yellow , ' blue ,
 
: SETBG ( n -- )  cells bg + @ execute ;
 
$1B  constant Esc
 
: D* ( ud1 ud2 -- ud ) \ multiply doubles
  >r swap >r 2dup um* rot r> * + rot r> * + ;
 
\ Random number generator
2variable Seed  1. seed 2!
: Random ( -- u )  seed 2@ $015A4E35. d* 1. d+ tuck seed 2! ;
: Rand ( u -- 0..u-1 )  random um* nip ;
\ : Randomize ( -- )  $40 $6C @l seed ! ;  \ from PC tick timer
 
\ Array access
: )  ( adr idx -- adr' )  cells + ;
: )@ ( adr idx -- n )  ) @ ;
: )! ( n adr idx -- )  ) ! ;
 
create Box  16 cells allot    \ Tiles array
 
0 value Moved
0 value I0
0 value DI
0 value K
variable Score
 
: ShowScore ( -- )
  30 5 at-xy  black  ." Score: "  Score @ u. ;
 
: ShiftTiles ( I0 DI -- )     \ Shift tiles, add adjacents, shift again
  to DI  to I0
 
  false ( Done flag)
  begin
      3 0 do                  \ shift all tiles in a single row or column
          I0 to K
          3 0 do
              Box K )@ 0=  Box K DI + )@  and  if
                  Box K DI + )  dup @ Box K )!  0 swap !
                  true to Moved
              then
              K DI + to K
          loop
      loop
      ( flag) if  exit  then
 
      true ( Done)
      I0 to K                 \ add identical adjacent tiles into a new tile
      3 0 do
          Box K )@  dup  Box K DI + )@  =  and  if  \ non-zero and equal
              1 Box K ) +!  0 Box K DI + )!  true to Moved
              1 Box K )@  lshift  dup Score +!  ShowScore
              2048 = if ."   You Won!" then
          then
          K DI + to K
      loop                    \ loop back to close any gaps that were opened
  again ;
 
: InsertTile ( -- )
  begin                                    \ in a random empty location
      Box  16 Rand  dup to K  )@  0=
  until
  2  10 Rand if 1- then  Box K )!          \ insert a 2^1=2 or 2^2=4
;
 
0 value X   0 value Y
 
: ShowBoard ( -- )
  16 0 do                                  \ show board with its tiles
      i  3 and     5 +  6 *  to X          \ get coordinates of tile
      i  2 rshift  3 *  6 +  to Y
      Box i )@  1+  7 and  Setbg           \ set color based on tile value
      3 0 do                               \ draw a square (6*8x3*16)
          X  Y i +  at-xy  6 spaces
      loop
      Box i )@  if                         \ box contains a tile
          1  Box i )@ lshift  (u.)         \ get value & cvt to string
          6 1+ over - 2/ X +  Y 1+  at-xy  \ center it
          type                             \ display
      then
  loop ;
 
0 value Ch
 
: NextMove ( -- )
  false to Moved                           \ a tile must move to continue
  begin
      GetKey to CH                         \ get key code
      0 3 do                               \ for all rows or columns
          Ch case
              k-left  of  i 4 *      1 ShiftTiles   endof
              k-right of  i 4 * 3 + -1 ShiftTiles   endof
              k-down  of  i 12 +    -4 ShiftTiles   endof
              k-up    of  i          4 ShiftTiles   endof
              Esc     of  Normal  +Cursor  0 18 at-xy  quit  endof
              ( other )                    \ ignore all other keys
          endcase
      -1 +loop
  Moved until ;
 
: Program ( -- )
  -Cursor                                  \ hide cursor
  Bright
\  Randomize                                \ randomize number generator
  Box 16 cells erase                       \ empty the box of tiles
  0 Score !                                \ zero score
  Page  ShowScore
  begin
      InsertTile
      ShowBoard
      NextMove
  again ;
 
program
 
