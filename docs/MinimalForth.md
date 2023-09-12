# MinimalForth.md

Not really a minimal set of words but adequate primitive words for make any standart, or quasi, Forth

Those need be assembled and uses as registers:

      - RS, return stack
      - PS, parameter stack
      - TOS, top of parameter stack
      - NOS, next on parameter stack
      - WRK, scratch generic
      - CNT, scratch generic
      
      - SP, system return stack reserved
      - ZR, zero hardware register
      
PS. 
      Most ideas from eForth, from Bill Muench and Chen-Hanson Ting. 
      Assuming a 16-bit big endian processor, (one is 0x0001)

### primitives

| word | does | obs |
| -- | -- | -- |
| ENDS | address interpreter | next, nest, unnest, jump, link |
| NOP | no operation | ( -- ) |
| FALSE | false flag, puts flag at TOS | ( -- F ) |
| TRUE | true flag, puts flag at TOS  | ( -- T ) |
| 0= | test if w == 0 | ( w -- F or T ) |
| 0< | test if w < 0 | ( w -- F or T ) |
| AND | logical AND | ( u u -- w ) |
| OR | logical OR | ( u u -- w ) |
| XOR | logical XOR | ( u u -- w ) |
| NAND | logical NOT AND | ( u u -- w ) |
| INVERT | one complement 0x00 ~ 0xFF | ( u -- v ) |
| NEGATE | two complement 0x02 ~ 0xFE | ( u -- v ) |
| LSHR | logic shift right, zero padded | ( u -- u ) |
| LSHL | logic shift left, zero padded | ( u -- u ) |
| UM+ | unsigned add with carry | ( w1 w2 -- w3 carry ) |
| UM< | unsigned less than | ( w1 w2 -- flag ) |
| BRANCH | branches to next absolute reference | ( -- ) |
| ZBRANCH | if TOS == 0, branches to next absolute reference | ( -- ) |
| ! | STORE word into a | ( w a -- ) |
| @ | FETCH word from a | ( a -- w ) |
| C! | C-STORE char into a | ( c a -- ) |
| C@ | C-FETCH char from a | ( a -- c ) |
| DROP | drop TOS | ( w -- )|
| DUP | duplicate TOS | ( w -- w w ) |
| OVER | copy second to top | ( w1 w2 -- w1 w2 w1 ) |
| SWAP | exchange first and second | ( w1 w2 -- w2 w1 ) |
| ROT |  cycle order of stack | ( w1 w2 w3 -- w2 w3 w1 ) |
| >R | place TOS at top of return stack | ( w -- ; -- w ) |
| R> | place top of return stack at TOS | ( -- w ; w -- ) |
| R@ | copy top of return stack to TOS | ( w -- w ; -- w ) |
| RP! | place TOS at RP | ( w -- ; -- ) |
| SP! | place TOS at SP | ( w -- ; -- ) |
| RP@ | place RP at TOS | ( -- w ; -- ) |
| SP@ | place SP at TOS | ( -- w ; -- ) |
| CHAR | size of a char to TOS | (  -- char ) |
| CHAR+ | add the size of a char to TOS | ( w -- w + char ) |
| CHAR- | add the size of a char to TOS | ( w -- w - char ) |
| CELL | size of a cell to TOS | (  -- cell ) |
| CELL+ | add the size of a cell to TOS | (  w -- w + cell ) |
| CELL- | add the size of a cell to TOS | (  w -- w - cell ) |
| ALIGNED | align a address into cell size | ( w -- +w+ ) |
|  0 | place 0x0000 into TOS | ( -- 0 ) |
| LIT | places the value of next cell at return stack into TOS, advance next cell |
| EXE | places the value from TOS into next cell at return stack |

| word | does | obs |
| -- | -- | -- |
| JMP | execute a jump (faith) to assembler code at TOS address | ( a -- ) |
| = | test if w1 == w2 | ( w1 w2 -- F or T ) |
| < | test if w1 < w2 | ( w1 w2 -- F or T ) |
| ASHR (2/)| math 2's shift right, sign preserved | ( w -- w ) |
| ASHL (2*)| math 2's shift left, sign preserved | ( w -- w ) |
| >< | exchanges lsb and msb, 0x0102 ~ 0x0201 | ( uv -- vu )
| +1 | place 0x0001 into TOS | ( -- 1 ) |
| -1 | place 0xFFFF into TOS | ( -- 2 ) |

### BIOS dependent

| word | does | obs |
| -- | -- | -- |
| BYE | standart ends the forth instance | ( c -- ) bios |
| KEY? | check if have a char from standart usart | ( -- c ) bios |
| KEY | get a char from standart usart | ( -- c ) bios |
| EMIT | put a char into standart usart | ( c -- ) bios |

| word | does | obs |
| -- | -- | -- |
| PEEK | get a byte from a I/O port | ( io -- c ) bios |
| POKE | put a byte into a I/O port | ( c io -- ) bios |
| _IRQR_ | declare a interrupt routine |

### Constants

| constants | used for | reference |
| -- | -- | -- |
| FALSE | value for Forth flag FALSE | wide wild walk |
| TRUE | value for Forth flag TRUE | wide wild walk |
| SS0 | system stack start | reserved non forth routines |
| RP0 | forth return stack start | internal forth stack |
| SP0 | forth parameter stack start | internal forth stack |
| TIB0 | forth terminal input buffer start | internal forth buffer |
| #SS | size of system stack in cells | depends |
| #RP | size of return stack in cells | depends |
| #SP | size of parameter stack in cells | depends |
| #TIB | size of forth terminal input buffer in cells | |

### Variables

| variables | used for | reference |
| -- | -- | -- |
| TOIN | cursor at TIB | next char in TIB |
| STATE | state of forth word interpreter | interpret, compiling, executing |
| BASE | radix for number conversion | reference for number digits |
| DP | dictionary pointer | next cell for dictionary entry |
| LATEST | link for last word defined | linked list entry |
| DSK | disk device | 1024 bytes |
| BLK | block number | 1024 bytes |
| SCR | screen number | 16 lines of 64 chars |
| SOURCE | input/output source | -1 = buffer, 0 = usart, 1 = file, i2c, spi, bluetooth, wi-fi, etc... |
| CSP | keep sp | transacional |
| HND | handler | catch and throw | 
| HLD | convert | <# # #> SIGN | 

### if CPU have math: 

| word | does | obs |
| -- | -- | -- |
| + | arithimetic plus | ( w1 w2 -- w1+w2 ) |
| - | arithimetic minus | ( w1 w2 -- w1+w2 ) |
| * | arithimetic multiply | ( w1 w2 -- w1+w2 ) |
| / | arithimetic quotient | ( w1 w2 -- w1/w2 ) |
| /MOD | arithimetic remainder | ( w1 w2 -- w1/w2 ) |
 
### if MCU/CPU have flash, eeprom and sram:

| word | does | obs |
| -- | -- | -- |
| flash | load a flash page into a sram address at TOS | CPU dependent |
| flush | save a flash page from a sram address at TOS | CPU dependent |
| eflash | load a eeprom page into sram address at TOS | CPU dependent |
| eflush | save a eeprom page from sram address at TOS | CPU dependent |

| constants | used for | reference |
| -- | -- | -- |
| #flash | size of a flash page | CPU dependent |
| #eflash | size of a eeprom page | CPU dependent |

| variable | used for | reference |
| -- | -- | -- |
| FP | heap flash pointer | next cell for flash, forward |
| EE | heap eeprom pointer | next cell for eeprom, forward |
| HP | heap sram pointer | next cell for sram, forward |
| UP | last sram pointer | last cell for sram, backward |



