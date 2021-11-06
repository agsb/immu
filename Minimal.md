
# About minimal core set

_Looking for a graal ? That's one._

## An list of atomic's was done by Mikael Patel as 

        S@ R@ @ ! nand plus 0= exit

## https://github.com/uho/minimal, Ulrich Hoffmann points Minimal Forth Workbench: 

    words ALIGNED CELL+ CHAR+ ROT 2/ LSHIFT XOR OR > = 0= TRUE FALSE MOD 2* / * + VARIABLE 
    CONSTANT DUP primitive WORDS INCLUDE bye \ .S ( CR KEY? EMIT KEY DOES> ; CREATE : 
    EXECUTE J LOOP UNTIL AGAIN BEGIN ELSE ' I DO REPEAT WHILE THEN IF R> OVER DROP R@ >R 
    SWAP RSHIFT INVERT AND < - */MOD CHARS CALIGNED CALIGN C@ C, C! CELLS ALIGN @ , ! 

    48 primitives, 69 words ok

## http://www.euroforth.org/ef15/papers/knaggs.pdf, Peter Knaggs and Paul E. Bennett, proposed:

1 Memory Access

        6.1.0010 ! store
        6.1.0150 , comma
        6.1.0650 @ fetch
        6.1.0705 ALIGN
        6.1.0706 ALIGNED
        6.1.0880 CELL+ cell-plus
        6.1.0890 CELLS
        6.1.0850 C! c-store
        6.1.0860 C, c-comma
        6.1.0870 C@ c-fetch
            CALIGN c-allign
            CALIGNED c-alligned
        6.1.0897 CHAR+ char-plus
        6.1.0898 CHARS chars
        
2 Arithmetic

        6.1.0120 + plus
        6.1.0090 * star
        6.1.0320 2* two-star
        6.1.0110 */MOD star-slash-mod
        6.1.0160 - minus
        6.1.0230 / slash
        6.1.0330 2/ two-slash
        6.1.1890 MOD
        
3 Logic

        6.1.0270 0= zero-equals
        6.1.0480 < less-than
        6.1.0720 AND
        6.1.1720 INVERT
        6.2.2298 TRUE
        6.1.1805 LSHIFT l-shift
        6.1.0530 = equals
        6.1.0540 > greater-than
        6.1.1980 OR
        6.1.2490 XOR x-or
        6.2.1485 FALSE
        6.1.2162 RSHIFT r-shift
        
4 Stack

        6.1.1290 DUP dupe
        6.1.2260 SWAP
        6.1.0580 >R to-r
        6.1.2070 R@ r-fetch
        6.1.1260 DROP
        6.1.1990 OVER
        6.1.2060 R> r-from
        6.1.2160 ROT rote
        
5 Flow Control

        6.1.1700 IF
        6.1.2270 THEN
        6.1.2430 WHILE
        6.1.2140 REPEAT
        6.1.1240 DO
        6.1.1680 I
        6.1.0070 ’ tick
        6.1.1310 ELSE
        6.1.0760 BEGIN
        6.2.0700 AGAIN
        6.1.2390 UNTIL
        6.1.1800 LOOP
        6.1.1730 J
        6.1.1370 EXECUTE
        
6 Definitions

        6.1.0450 : colon
        6.1.0950 CONSTANT
        6.1.1000 CREATE
        6.1.0460 ; semicolon
        6.1.2410 VARIABLE
        6.1.1250 DOES> does
        
7 Device

        6.1.1750 KEY
        6.1.1320 EMIT
        10.6.1.1755 KEY? key-question
        6.1.0990 CR c-r
        
8 Tools

        6.1.0080 ( paren
        15.6.1.0220 .S dot-s
        6.2.2535 \ backslash
        
        
