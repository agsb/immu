# Notes

- found a asm coding style: http://www.sourceformat.com/pdf/asm-coding-standard-brown.pdf

- little RISC-V board from https://mecrisp-stellaris-folkdoc.sourceforge.io/gd32vf103.html

- in above board, USART 0 BASE $40013800

- Brad Nelson, 02/2022, mastered easy way
    
    : ( 44 parse drop drop ; immediate
   
    : \ 10 parse drop drop ; immediate
   
    ( now we have 
    multi line 
    comments )
    
    \ also only to end of line

    : constant ( n 'name' -- ) create , does> @ ;
    : variable ( 'name' -- ) create 0 , ;
    


