
@from: https://pastebin.com/qpZLFc6h

```
Forth Naming Conventions ('Thinking FORTH')
-------------------------------------------
 
Meaning                             Form            Example
 
Arithmetic
----------
integer 1                           1name           1+
integer 2                           2name           2*
takes relative input parameters     +name           +DRAW
takes scaled input parameters       *name           *DRAW
 
Compilation
-----------
start of "high-level" code          name:           CASE:
end of "high-level" code            ;name           ;CODE
put something into dictionary       name,           C,
executes at compile time            [name]          [COMPILE]
slightly different                  name' (prime)   CR'
internal form or primitive          (name)          (TYPE)
                                    or <name>       <TYPE>
compiling word run-time part:
  systems with no folding           lower-case      if
  systems with folding              (NAME)          (IF)
defining word                       :name           :COLOR
block-number where overlay begins   namING          DISKING
 
Data Structures
---------------
table or array                      names           EMPLOYEES
total number of elements            #name           #EMPLOYEES
current item number (variable)      name#           EMPLOYEE#
sets current item                   ( n) name       13 EMPLOYEE
advance to next element             +name           +EMPLOYEE
size of offset to item from         name+           DATE+
  beginning of structure
size of (bytes per)                 /name           /EMPLOYEE
  (short for BYTES/name)
index pointer                       >name           >IN
convert address of structure to     >name           >BODY
  address of item
file index                          (name)          (PEOPLE)
file pointer                        -name           -JOB
initialize structure                0name           0RECORD
 
Direction, Conversion
---------------------
backwards                           name<           SLIDE<
forwards                            name>           CMOVE>
from                                <name           <TAPE
to                                  >name           >TAPE
convert to                          name>name       FEET>METERS
downward                            \name           \LINE
upward                              /name           /LINE
open                                {name           {FILE
close                               }name           }FILE
 
Logic, Control
--------------
return boolean value                name?           SHORT?
returns reversed boolean            -name?          -SHORT?
address of boolean                  'name?          'SHORT?
operates conditionally              ?name           ?DUP
                                                    (maybe DUP)
enable                              +name           +CLOCK
 or, absence of symbol              name            BLINKING
disable                             -name           -CLOCK
                                                    -BLINKING
Memory
------
save value of                       @name           @CURSOR
restore value of                    !name           !CURSOR
store into                          name!           SECONDS!
fetch from                          name@           INDEX@
name of buffer                      :name           :INSERT
address of name                     'name           'S
address of pointer to name          'name           'TYPE
exchange, especially bytes          >name<          >MOVE<
 
Numeric Types
-------------
byte length                         Cname           C@
2 cell size, 2's complement         Dname           D+
  integer encoding
mixed 16 and 32-bit operator        Mname           M*
3 cell size                         Tname           T*
4 cell size                         Qname           Q*
unsigned encoding                   Uname           U.
 
Output, Printing
----------------
print item                          .name           .S
print numeric (name denotes type)   name.           D. , U.
print right justified               name.R          U.R
 
Quantity
--------
"per"                               /name           /SIDE
 
Sequencing
----------
start                               <name           <#
end                                 name>           #>
 
Text
----
string follows delimited by "       name"           ABORT" text"
text or string operator             "name           "COMPARE
  (similar to $ prefix in BASIC)
superstring array                   "name"          "COLORS"
 
 
Forth Naming Conventions ('Forth Programmer's Guide')
-----------------------------------------------------
 
Where possible, a prefix before a name indicates the type or
precision of the value being operated on, whereas a suffix
after a name indicates what the value is or where it is stored.
 
Format    Meaning                                   Example
 
!name     Store into name                           !DATA
 
#name     Size or quantity                          #PIXELS
          Output numeric operator                   #S
          Buffer name                               #I
 
'name     Address of name                           'S
          Address of pointer to name                'TYPE
 
(name)    Internal component of name, not           (IF)
          normally user-accessible                  (FIND)
          Run-time procedure of name                (:)
          File index                                (PEOPLE)
 
*name     Multiplication                            *DIGIT
          Takes scaled input parameter              *DRAW
 
+name     Addition                                  +LOOP
          Advance                                   +BUF
          Enable                                    +CLOCK
          More powerful                             +INITIALIZE
          Takes relative input parameters           +DRAW
 
-name     Subtract, remove                          -TRAILING
          Disable                                   -CLOCK
          not name (opposite of name)               -DONE
          Returns reversed truth flag               -MATCH
          (1 is false, 0 is true)
          Pointers, especially in files             -JOB
 
.name     Print named item                          .S
          Print from stack in named format          .R .$
          Print following string                    ." string"
          May be further prefixed with data type    D. U. U.R
 
/name     Division                                  /DIGIT
          Initialize routine or device              /COUNTER
          "per"                                     /SIDE
 
1name     First item of a group                     1SWITCH
          Integer 1                                 1+
          One-byte size                             1@
 
2name     Second item of a group                    2SWITCH
          Integer 2                                 2/
          Two-cell size                             2@
 
;name     End of something                          ;S
          End of something, start of something      ;CODE
          else
 
<name     Less than                                 <LIMIT
          Open bracket                              <#
          From device name                          <TAPE
 
<name>    Name of an internal part of a device      <TYPE>
          driver routine
 
>name     Towards name                              >R, >TAPE
          Index pointer                             >IN
          Exchange, especially bytes                >< (swap bytes)
                                                    >MOVE< (move,
                                                    swapping bytes)
 
?name     Check condition, return true if yes       ?TERMINAL
          Conditional operator                      ?DUP
          Check condition, abort if bad             ?STACK
          Fetch contents of name and display        ?N
 
@name     Fetch from name                           @INDEX
 
Cname     One-byte character size, integer          C@
 
Dname     Double-cell integer                       D+
 
Mname     Mixed single and double operator          M*
 
Tname     Three-cell size                           T*
 
Uname     Unsigned encoding                         U.
 
[name]    Executes at compile time                  [']
 
\name     Unsigned subtraction (ramp-down)          \LOOP
 
name!     Store into name                           B!
 
name"     String follows, delimited by "            ABORT" xxx"
 
name,     Put something into dictionary             C,
 
name:     Start definition                          CASE:
 
name>     Close bracket                             #>
          Away from name                            R>
 
name?     Same as ?name                             B?
 
name@     Fetch from name                           B@
 
``` 
 
