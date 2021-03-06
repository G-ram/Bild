type token =
  | LPAREN
  | RPAREN
  | LBRACE
  | RBRACE
  | LBRACK
  | RBRACK
  | PLUS
  | MINUS
  | TIMES
  | DIVIDE
  | MOD
  | INCREMENT
  | DECREMENT
  | LT
  | GT
  | LEQ
  | GEQ
  | EQ
  | NEQ
  | AND
  | OR
  | QUEST
  | NEGATE
  | FORCE
  | OF
  | IS
  | ASSIGN
  | PLUSASSIGN
  | MINUSASSIGN
  | TIMESASSIGN
  | DIVIDEASSIGN
  | MODASSIGN
  | FORCEASSIGN
  | FUN
  | TYPE
  | IMPORT
  | PRINT
  | RAISE
  | BREAK
  | RETURN
  | TRY
  | CATCH
  | INLINE
  | IF
  | ELIF
  | ELSE
  | FOR
  | WHILE
  | IN
  | MATCH
  | WHEN
  | SEMI
  | COLON
  | COMMA
  | PERIOD
  | VERT
  | NEWLINE
  | UNDER
  | EOF
  | CPP_STRING of (string)
  | STRING of (string)
  | INT of (int)
  | DOUBLE of (float)
  | CHAR of (char)
  | BOOL of (bool)
  | ID of (string)
  | OPTID of (string)

val program :
  (Lexing.lexbuf  -> token) -> Lexing.lexbuf -> Ast.program
