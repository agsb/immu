
%s/([^)]*)//g
%s/ COMPILE-ONLY //
%s/ iIMMEDIATE //
%s/\r\r/\n/
%s/  / /g
# for each line start : join lines until ends in ;
grep -E '^: ' sec > sec.words
grep -v -E '^: ' sec > sec.cntes

# in sec.cntes
:%s/VARIABLE \([^ ]*\)/: \1 VARIABLE ;/
:%s/CONSTANT \([^ ]*\)/: \1 CONSTANT ;/
