#/usr/bin/bash

case $1 in
    x)
    make clean ; rm err out ;
    ;;
    c)
    make clean ; make 2> err 1> out
    ;;
    s)
    simavr -m atmega8 -f 8000000 -t -g -v -v
    ;;
esac

grep HEADER *.S > words
