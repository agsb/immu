\ T3XFORTH -- Misc. system-related utility words
\ Nils M Holm, 2021
\ Public domain / CC0 License

\ Index only blocks with differing titles
: DIR ( n1 n2 -- ) PAD B/LINE ERASE
  1+ SWAP DO I BLOCK >R  R@ B/LINE PAD -TEXT IF
      CR I' 0 .R ." : " R@ B/LINE TYPE
      R@ PAD B/LINE CMOVE THEN
    R> DROP LOOP ;

\ Find duplicate dictionary entries
: .ID  COUNT 31 AND DUP . 5 MIN TYPE SPACE ;
: CHECK CONTEXT @ @ BEGIN DUP WHILE
    CONTEXT @ @ BEGIN DUP WHILE
      2DUP ?SAME >R 2DUP U< R> AND IF
        CR DUP .ID 2DUP H. H. THEN
      >LFA @ REPEAT DROP  >LFA @ REPEAT DROP ;

\ Save the system to the first disk blocks
: SAVE-SYSTEM ( -- ) HERE 32768 U> ABORT" SIZE ERR"
  HERE 256 - 1023 + 1024 / 0 DO
    I 1+ BUFFER  I 1024 * 256 + SWAP 1024 CMOVE
    UPDATE FLUSH  I .  LOOP  EMPTY-BUFFERS
    HERE 256 - . ;

VARIABLE TMP

\ Print description of a word
: HELP ( -- ) BL WORD DUP UPCASE TMP !
  S.GLOSSARY 1+ SWAP DO  I BLOCK  16 0 DO
      DUP I B/LINE * + TMP @ COUNT ROT -TEXT 0= IF
        DUP I B/LINE * + TMP @ C@ + 2 $"  (" 1+ -TEXT 0= IF
        J LIST  UNLOOP UNLOOP DROP EXIT THEN  THEN
      LOOP  DROP LOOP  ;
