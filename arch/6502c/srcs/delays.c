#include  <stdlib.h>
#include  <stdio.h>


/* 

03/10/2023, agsb@

calculate delay for 6502 dual loop

results in ms, with ns precision

includes call and return times

;   6 call
@loop:
     txa            ; 2 Get delay loop 
@y_delay:
     tax            ; 2 Get delay loop
@x_delay:
     dex            ; 2
     bne @x_delay   ; 2
     dey            ; 2
     bne @y_delay   ; 2
     rts            ; 6 return
*/

int main ( int argc, char * argv[]) {

// clock in nanosec
// for 0.9216 MHz 
#define clock 1.0850695 

int dx, dy;
long int m;
double p;

for (dx=1; dx < 256; dx++) {
for (dy=1; dy < 256; dy++) {

    m = 7 * dx + 4 * dx * dy + 15;

    p = (double) m * clock / 1000.0;

	printf (" %7.3lf ms %4d %4d\n", p, dx, dy);

} } 

return (0);
}

