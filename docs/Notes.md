# Notes

- found a asm coding style: http://www.sourceformat.com/pdf/asm-coding-standard-brown.pdf

- from https://mecrisp-stellaris-folkdoc.sourceforge.io/gd32vf103.html

    USART 0 BASE $40013800
    
![image](https://user-images.githubusercontent.com/14941647/153716690-2b28e3d4-9a0f-4757-b5f1-1dd8c0a44867.png)

BRAD NELSON
    
    : ( 44 parse drop drop ; immediate
   
    : \ 10 parse drop drop ; immediate
   
    ( now we have 
    multi line 
    comments )
    
    \ also only to end of line

    : constant ( n 'name' -- ) create , does> @ ;
    : variable ( 'name' -- ) create 0 , ;
    


