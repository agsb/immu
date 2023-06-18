( still in WIP )

__" PROGRAMMING A PROBLEM-ORIENTED LANGUAGE", Charles H. Moore, june, 1970__

# Why split the dictionaries ?

Essentially the Forth dictionary is a sequence of references to fixed address for code that is executed by the inner interpreter. After the compilation, the headers are only usefull for human understandings using SEE and SHOW.

When no interaction and no compilation is done, there is no need of headers. 

## For save memory space. 

"A Seeed Studio GD32VF103 device is a 32-bit general-purpose microcontroller based on the RISC-V core, it provides 128 KB on-chip Flash memory and 32 KB SRAM memory", KB is kilobytes. 

Since the Forth cells use the native size of the processor registers, which on a 32-bit CPU is a double word, it's really a "32k double-word flash and 8k double-word sram" memory system. Almost nothing in a world of gigabytes of sram at cellphones in hands, where Forth is just a application.

But for for a bare metal system in the real problem-oriented-world, is a determinant factor and double words is a waste of resources. 

The flash memory can not (must not) be used for stacks, buffers, values and variables, those must be keeped at sram.
PS. for sake, a byte is 8-bit, a word is 16-bit, a double word is 32-bit, a long word is 64-bit.

### Memory Models

Let us use a linear memory model with Bios, System, Forth with \[Core, Vocabularies, free-memory, TIB, PAD, DataStack, ReturnStack], SystemStack. 

The Bios is basic input, output and clock routines; the System is operational routines with access formats and protocols; the Forth is a Forth system with, Core words, Vocabularies words, TIB and PAD buffers, DataStack and ReturnStack for Forth use; and the SystemStack for System use.

The free-memory could be of flash and sram. 

Using Forth classic model, the dictionary is a sequence of pairs \[header,code] that grow from heap to stack. The proposed Forth simple model, and the list of \[code] grow from heap and the list of \[header] from stack. Separated lists of code and headers are used in very first implementations of Forth and in modern Forth, using C language.

