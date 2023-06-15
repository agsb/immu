
# Branch

In Forth there is really only BRANCH and ?BRANCH as code for change the sequential execution. All custon controls uses these, but the fundamental question is about is absolute or relative.

the FIG-FORTH PDP-11, 1980, uses relative branching " ADD (IP), IP ".

In IMMU, using MITC, all code is make using jumps, early I try simplify using only absolute address, more eficient because no addition need. 

But there is a "catch 22". 

## How do ?

How map memory address spaces for eeprom, flash memory and static memory ?
 
In last century, all systems resides in continous memory address space, part ROM and part RAM, but modern MCUs and CPUs, have eeprom, flash and sram memory address spaces. 

the BIOS system and static Forth dictionary, are usually located in eeprom or flash memory space, and the vocabularies for libraries and applications, could be loaded from a midia device, formatted as screens and blocks, and compiled into a dynamic Forth dictionary into ram memory space. 

But when some of these temporary code must be compiled and preserved as permanent extention of Forth dictionary ? Eg, a specific aplication for a microcontroler that monitors sensors and controls motors.

There is a trivial solution, load, compile, execute at ever boot. Or extend the static dictionary.

When using sdram and flash memories, as in modern RISC CPUs or MCUs, the code is compiled in sram and must be moved to flash. For pointers of words already in flash memory dictionary, no changes in word address pointers, but for new words and branches, must adjust all address to relative offsets.

Some MCUs, have Harvard model, with Flash and SRAM memories in diferent spaces.

(to be continued)

//  branch for absolute address.
//  sequence is:    
//  ...
//  MEM-0   address_of_branch
//  MEM-1   absolute_address
//  ...
_branch:
    rspull zpm_low, zpm_high  // get absolute address from return stack
    pmload nos_low, nos_high  // load the content of absolute address 
    rspush nos_low, nos_high  // put absolute address into return stack
    jump _link                // continue 
 
 HOW DO "IP = IP + (IP)" WHEN THERE IS NO IP ? // there is no spoon
 
 
All RISC_V ISA uses only relative address offsets for jumps.
