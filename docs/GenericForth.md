# Generic forth

## Minimal Forth

https://github.com/project-forth-works/project-forth-works.github.io/blob/main/minimalforth.md

ALIGNED CELL+ CHAR+ ROT 2/ LSHIFT XOR OR > = 0= TRUE FALSE MOD 2* / * + VARIABLE CONSTANT DUP 
WORDS INCLUDE bye \ .S ( CR KEY? EMIT KEY DOES> ; CREATE : EXECUTE J LOOP UNTIL AGAIN BEGIN ELSE 
' I DO REPEAT WHILE THEN IF R> OVER DROP R@ >R SWAP RSHIFT INVERT AND < - */MOD CHARS CALIGNED 
CALIGN C@ C, C! CELLS ALIGN @ , ! 
