#!/usr/bin/gnuplot
######################################## 
reset 
fn = 'gnuplot/hexagon.dat' 
S = 0.5 
C = sqrt(3)/2 
A = 1/C 
a = 0.95*A 

hex_id = 1 

cmd = '' 

hex_cmd(x, y, c) = sprintf("\nset obj hex_id poly from %g,%g-a to %g+a*C,%g-a*S to %g+a*C,%g+a*S to %g,%g+a to %g-a*C,%g+a*S to %g-a*C,%g-a*S to %g,%g-a fs solid 0.8 border lc pal cb %g lw 2 fc pal cb %g; hex_id = hex_id + 1;", x,y,x,y,x,y,x,y,x,y,x,y,x,y,c,c) 

read_f(x, y, c) = (cmd=cmd.hex_cmd(x, y, c), y) 

set term x11

plot fn u 1:(read_f($1,$2,$3)) 

set term pop 
#print cmd
eval cmd 
#set palette rgbformulae 33,13,10
set palette rgbformulae -10,-13,-23
#set palette rgbformulae 30,31,32
set size ratio -1 
set xr [GPVAL_X_MIN-A:GPVAL_X_MAX+A] 
set yr [GPVAL_Y_MIN-A:GPVAL_Y_MAX+A] 

plot fn u 1:2:3 w d lc pal notit 

################################### 