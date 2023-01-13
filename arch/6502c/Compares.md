# Compare Forth implementations

Traditional Forths for 6502 ISA, uses return stack in SP (page one), 
data stack in page zero indexed by X register, tos in A and Y registers,
but how it compares with an alternative, using absolute memory $200 and $300
as return and data stacks, indexed by Y and X, and free A register ?

Comparing, (bytes, cycles operation)

1. Direct access

| bytes | cycles | operation |
| -- | -- | -- |
|classic|
|1, |3,  |pha |
|1, |4,  |pla |
|2, |4,  |sta/lda zp, x |
|2, |4,  |ops zp, x |     
|2, |4,  |sbc/adc zp, x |
|2, |6,  |dec/inc zp, x |

| bytes | cycles | operation |
| -- | -- | -- |
|alternative |
|3, |4,  |sta/lda abs, x/y |
|3, |4,  |ops abs, x |
|3, |4,  |sbc/adc abs, x/y |
|3, |7,  |dec/inc abs, x/y |

As the cycles are about same then the great difference is size of result code
(ops is any of xor, or, and, ror, rol, asl, lsl) 

2. Indirect access
2, 6  sta (zp,X)  
2, 6  sta (zp),Y  
