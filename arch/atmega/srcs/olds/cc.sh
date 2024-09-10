

avr-gcc -c -mmcu=atmega328 -I. -x assembler-with-cpp -Wa,-adhlns=$1.lst $1.S -o $1.o

avr-gcc -mmcu=atmega328 -I. -gstabs -O0 -DF_CPU=8000000  -fverbose-asm -fshort-enums -Wall -Wstrict-prototypes -Wa,-adhlns=$1.o  -std=gnu99 -nostartfiles -nostdlib -nostartfiles -Wp,-M,-MP,-MT,$1.o,-MF,.dep/$1.elf.d $1.o   --output $1.elf -Wl,-Map=$1.map,--cref

