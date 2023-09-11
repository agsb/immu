\ T3XFORTH Double Words
\ Nils M Holm, 2021
\ Public domain / CC0 License

: 2ROT ( d1 d2 d3 -- d2 d3 d1 ) >R >R 2SWAP R> R> 2SWAP ;

: D0= ( d -- f ) OR 0= ;

: D0< ( d -- f ) NIP 0< ;

: D- ( d d -- d ) DNEGATE D+ ;

: DU< ( ud ud -- f ) ROT SWAP U< IF 2DROP -1 EXIT THEN U< ;

: D= ( d d -- f ) ROT = -ROT = AND ;

: D> ( d d -- f ) 2SWAP D< ;

: DABS ( d -- ud ) 2DUP 0 0 D< IF DNEGATE THEN ;

: DMAX ( d1 d2 -- d ) 2OVER 2OVER D< IF 2SWAP THEN 2DROP ;
: DMIN ( d1 d2 -- d ) 2OVER 2OVER D> IF 2SWAP THEN 2DROP ;

VARIABLE TMP 0 ,

: DU* ( ul1 uh1 ul2 uh2 -- ud ) >R >R  ( i'=uh2 i=ul2 )
  OVER I' UM* DROP 0 SWAP TMP 2!       (   ul1 * uh2 * 2^16)
  I UM* DROP 0 SWAP TMP 2@ D+ TMP 2!   ( + uh1 * ul2 * 2^16)
  R> UM* TMP 2@ D+                     ( + ul1 * ul2 )
  R> DROP ;

: UDM/MOD ( ul uh u -- um ul uh )
  2DUP 0 SWAP UM/MOD  ( ul uh u mod uh/u )
  >R >R NIP R> SWAP   ( ul mod u ; uh/u )
  UM/MOD R> ;

: <# ( ud -- ud ) PAD HLD ! ;

: # ( ud -- ud ) BASE @ UDM/MOD  ROT DIGIT HOLD ;

: #S ( ud -- 0d ) BEGIN # 2DUP D0= 0= WHILE REPEAT ;

: SIGN ( n ud -- ud ) ROT 0< IF [CHAR] - HOLD THEN ;

: #> ( ud -- a u ) 2DROP HLD @ PAD OVER - ;

: D.  ( d -- )      DUP -ROT DABS <# #S SIGN #> TYPE SPACE ;
: D.R ( d n -- ) >R DUP -ROT DABS <# #S SIGN #> R> (PAD) TYPE ;

: 2VARIABLE ( -- ) VARIABLE 0 , ;

: 2CONSTANT ( d -- ) <BUILDS , , DOES> 2@ ;

: CONVERT ( ud a -- ud a ) 1+  0 DBL !  BEGIN
    DUP C@ ?DIGIT IF ( d a digit )
      2SWAP BASE @ 0 DU* 0 -ROT D+ ROT 1+ ELSE
    DUP C@ [CHAR] , = IF 1+  -1 DBL !     ELSE
      EXIT THEN THEN  AGAIN ;

: ?NUMBER ( a -- d T | F )
  DUP 1+ C@ [CHAR] - = DUP >R IF 1+ THEN
  0 0 ROT CONVERT
  C@ BL <> IF 2DROP R> DROP 0 EXIT THEN
  R> IF DNEGATE THEN  -1 ;

: NUMBER ( a -- n | d ) DUP ?NUMBER IF ROT DROP
    DBL @ 0= IF DROP THEN EXIT THEN  ?WHAT ;

' NUMBER 'NUMBER !

: (FENCE) ;
' (FENCE) >NFA FENCE !

