
(in progress)

# Branchs

In Forth, all custon controls uses BRANCH and ZBRANCH for change the sequential execution, but the offset is absolute or relative ?

__the FIG-FORTH PDP-11, 1980, uses relative branching " ADD (IP), IP "__

Using MITC, all code is make using jumps, early I try simplify using only absolute address, more eficient because no addition need. 

__How do "ADD (IP), IP" when there is no IP ?__ // there is no spoon
 
Code example using AVR code of IMMU,

    0x0 CONSTANT NULL
    
    // BEGIN ... AGAIN compiles a backward branch
    : BEGIN HERE ;
    
    // IF ... THEN compiles a forward branch
    : IF ' ZBRANCH , HERE NULL , ; // place the reference for ZBRANCH and NULL at dictionary and leave HERE at stack

### When using absolute address:

    //  branch for absolute address.
    //  ...
    _branch:
        rspull zpm_low, zpm_high  // get absolute address from return stack into zpm
        pmload nos_low, nos_high  // load the content of absolute address from zpm
        rspush nos_low, nos_high  // put absolute address from zpm into return stack 
        jump _link                // continue 

    : AGAIN ' BRANCH , , ; // place a backward branch
    
    : THEN HERE SWAP ! ; // place the absolute address at ZBRANCH parameter
    
### When use relative address:

    //  branch for relative address.
    //  ...
    _branch:
        rspull zpm_low, zpm_high  // get absolute address from return stack
        movw wrk_low, zpm_low     // copy address 
        pmload nos_low, nos_high  // load the content of absolute address
        add nos_low, wrk_low      // add offset
        adc nos_high, wrk_high    // add offset
        rspush nos_low, nos_high  // put absolute address into return stack
        jump _link                // continue 

     : AGAIN ' BRANCH , HERE SWAP - , ;  
     
     : THEN HERE OVER - ! ; // place the offset at ZBRANCH parameter

But there is a "catch 22". 

## How do ?

How map memory address spaces for eeprom, flash memory and static memory ?
 
In last century, all systems resides in continous memory address space, part ROM and part RAM, but modern MCUs and CPUs, have eeprom, flash and sram memory address spaces. 

the BIOS system and static Forth dictionary, are usually located in eeprom or flash memory space, and the vocabularies for libraries and applications, formatted as screens and blocks, could be loaded from a midia device and compiled into a dynamic Forth dictionary into ram memory space. 

But when some of this temporary code must be compiled and preserved as permanent extention of Forth dictionary ? Eg, a specific aplication for a microcontroler that monitors sensors and controls motors.

A trivial solution, load, compile, execute at ever boot, or extend the static dictionary.

In modern RISC CPUs or MCUs, using sdram and flash memories, the code compiled in sram must be moved to flash. For pointers of words already in flash memory dictionary, no changes in word address pointers, but for new words and branches, must adjust all address to relative offsets.

Some MCUs, have Harvard model, with Flash and SRAM memories in diferent spaces.

(to be continued)

### Note 
 
All RISC_V ISA only uses relative address offsets for jumps but using jal (jump and link) could go to a absolute address.


