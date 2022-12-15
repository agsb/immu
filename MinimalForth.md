# MinimalForth.md

Not really a minimal set of words but adequate primitive words for make any standart, or quasi, Forth

Those need be assembled and uses as registers:

      - RS, return stack
      - PS, parameter stack
      - TOS, top of parameter stack
      - NOS, next on parameter stack
      - WRK, scratch generic
      
      - SP, system return stack reserved
      - ZR, zero hardware register
      
PS. Most ideas from eForth

### primitives

| word | does | obs |
| -- | -- | -- |
| (inner) | address interpreter | next, nest, unnest, jump, link |
| FALSE | false flag, puts 0x0000 at TOS | ( -- F ) |
| TRUE | true flag, puts 0xFFFF at TOS  | ( -- T ) |
| 0= | test if w == 0 | ( w -- F or T ) |
| 0< | test if w < 0 | ( w -- F or T ) |
| AND | logical AND | ( u v -- w ) |
| OR | logical OR | ( u v -- w ) |
| XOR | logical XOR | ( u v -- w ) |
| NAND | logical NOT AND | ( u v -- w ) |
| NEGATE | arithmetic inverse 0x02 ~ 0xFE | ( u -- v ) |
| INVERT | logic inverse 0x00 ~ 0xFF | ( u -- v ) |
| >< | exchanges lsb and msb, 0x0102 ~ 0x0201 | ( uv -- vu )
| UM+ | unsigned word add with carry | ( w1 w2 -- w1+w2 carry ) |
| 2/ | shift right one bit | ( w -- w >> 1 ) |
| 2* | shift left one bit | ( w -- w << 1 ) |
| BRANCH | branches to next absolute reference | ( -- ) |
| ZBRANCH | if TOS == 0, branches to next absolute reference | ( -- ) |
| ! | STORE word into a | ( w a -- ) |
| @ | FETCH word from a | ( a -- w ) |
| C! | C-STORE char into a | ( c a -- ) |
| C@ | C-FETCH char from a | ( a -- c ) |
| DROP | drop TOS | ( w -- )|
| DUP | duplicate TOS | ( w -- w w ) |
| SWAP | exchange first and second | ( w1 w2 -- w2 w1 ) |
| OVER | copy second to top | ( w1 w2 -- w1 w2 w1 ) |
| ROT |  cycle order of stack | ( w1 w2 w3 -- w2 w3 w1 ) |
| >R | place TOS at top of return stack | ( w -- ; -- w ) |
| R> | place top of return stack at TOS | (  -- w ; w -- ) |
| R@ | copy top of return stack to TOS | ( w -- ; -- w ) |
| RS! | place TOS at RS | ( w -- ; -- ) |
| PS! | place TOS at PS | ( w -- ; -- ) |
| RS@ | place RS at TOS | ( w -- ; -- ) |
| PS@ | place PS at TOS | ( w -- ; -- ) |
| CELL | place the size of a cell at TOS | (  -- cell ) |
| ALIGNED | align a address into cell size | ( w -- w+ ) |
| 0 | place 0x0000 into TOS | ( -- 0 ) |
| 1 | place 0x0001 into TOS | ( -- 1 ) |
| 2 | place 0x0002 into TOS | ( -- 2 ) |
| JUMP | execute assembler code at TOS address | ( a -- ) |
| CALL | execute a external assembler code at TOS address using system stack pointer | ( a -- ) |

### BIOS dependent

| word | does | obs |
| -- | -- | -- |
| KEY? | check if have a char from standart usart | ( -- c ) bios |
| KEY | get a char from standart usart | ( -- c ) bios |
| EMIT | put a char into standart usart | ( c -- ) bios |
| PEEK | get a byte from a I/O port | ( io -- c ) bios |
| POKE | put a byte into a I/O port | ( c io -- ) bios |

### Constants

| constants | used for | reference |
| -- | -- | -- |
| SP0 | real cpu stack start | reserved for external routines |
| RS0 | forth return stack start | internal forth stack |
| PS0 | forth parameter stack start | internal forth stack |
| TIB0 | forth terminal input buffer start | internal forth buffer |
| #RS | size of return stack in cells | |
| #PS | size of paremeter stack in cells | |
| #TIB | size of forth terminal input buffer in cells | |

### Variables

| variables | used for | reference |
| -- | -- | -- |
| >TIB | cursor at TIB | next char in TIB |
| STATE | state of forth word interpreter | interpret, compiling, executing |
| BASE | radix for number conversion | reference for number digits |
| DP | dictionary pointer | next cell for dictionary entry |
| LATEST | link for last word defined | linked list entry |

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

