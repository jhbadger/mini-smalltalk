\ The part of the Forth system that is written in Forth.  It is read once, when the package loads,
\ and every new system starts with these words already defined.

: ?  ( a -- )  @ . ;
: BLANK  ( a u -- )  BL FILL ;
: ERASE  ( a u -- )  0 FILL ;
: MS  ( n -- )  DROP ;
: FALIGN  ( -- ) ;
: FALIGNED  ( a -- a ) ;
: ENVIRONMENT?  ( a u -- false )  2DROP 0 ;
: [COMPILE]  ( "name" -- )  ' COMPILE, ; IMMEDIATE

\ show a region of memory, a row of eight cells at a time, in hexadecimal
: DUMP  ( addr u -- )
   BASE @ >R  HEX
   0 ?DO
      I 8 MOD 0= IF CR DUP I + 5 U.R ." :" THEN
      DUP I + @ 5 U.R
   LOOP
   DROP CR
   R> BASE ! ;
