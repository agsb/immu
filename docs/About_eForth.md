# About eForth

(this fie is a stub)

## Greetings to eForth

## What I like

  - use of interrupt 021H interface of DOS.
  - a concise set of primitives (code) and compound (colon) words;
  - code and name separated dictionaries, "This arrangement has the advantage that the name dictionary can be
eliminated from a target system which does not use an interpreter.";
  - use of pointer to basic routines 'QKEY, 'EMIT, 'EXPECT, 'ECHO, 'PROMPT, 'EVAL, 'NUMBER, 'TAP;
  - use a common user area for forth variables and variables that return pointers inside that area;
  - use of vocabularies with current, context and a list for vocabularies

## What I do not 

  - direct thread code;
  - no multi-task concept;
  - direct address branch, absolute instead of relative;
  - use o 'call doLST' at begin of "colon words", wich ends in EXIT;
  - share TIB and return stack;
  - where is the DOS/SO stack;
  - that user area variables are not referenced by offsets;
  - a small, and fixed size, list for vocabularies;
  - only <0 as primitive;

