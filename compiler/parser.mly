%{
  open Ast
%}

%token LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK
%token PLUS MINUS TIMES DIVIDE MOD
%token INCREMENT DECREMENT
%token LT GT LEQ GEQ EQ NEQ AND OR
%token QUEST NEGATE FORCE
%token OF IS
%token ASSIGN PLUSASSIGN MINUSASSIGN TIMESASSIGN DIVIDEASSIGN MODASSIGN FORCEASSIGN
%token FUN TYPE IMPORT PRINT
%token RAISE BREAK RETURN
%token TRY CATCH
%token IF ELIF ELSE FOR WHILE IN MATCH WHEN
%token SEMI COLON COMMA PERIOD VERT NEWLINE SEMI UNDER
%token EOF
%token <string> STRING
%token <int> INT
%token <float> DOUBLE
%token <char> CHAR
%token <bool> BOOL
%token <string> ID OPTID
/*Precedence and associativity*/
%nonassoc NOOF
%nonassoc NOELSE
%nonassoc NOCOMMA
%nonassoc ELSE
%nonassoc ELIF
%nonassoc COMMA PERIOD RPAREN LPAREN RPAREN LBRACK RBRACK LBRACE RBRACE LBRACE SEMI UNDER
%nonassoc FUN TYPE PRINT
%nonassoc IF FOR WHILE IN MATCH WHEN CATCH RAISE BREAK RETURN
%nonassoc STRING INT DOUBLE CHAR BOOL ID OPTID
%nonassoc INCREMENT DECREMENT FORCE
%right ASSIGN PLUSASSIGN MINUSASSIGN TIMESASSIGN DIVIDEASSIGN MODASSIGN FORCEASSIGN
%left AND
%left OR
%left EQ NEQ IS
%left LT GT LEQ GEQ
%left PLUS MINUS
%left TIMES DIVIDE MOD
%nonassoc UMINUS
%nonassoc NEGATE
%nonassoc PREDECREMENT
%nonassoc QUEST
%nonassoc TRY TERTIARY

%start program
%type <Ast.program> program

%%
/*Program structure*/
program:
  imports parts EOF {($1, $2)}

parts:
  /* */ %prec NOCOMMA {[]}
  | part parts {$1 :: $2}

part:
  fxn {Fxn($1)}
  | typ %prec NOCOMMA {Typ($1)}
  | stmt {Stmt($1)}

imports:
  /* */ %prec NOCOMMA {[]}
  | import imports {$1 :: $2}

import:
  IMPORT STRING{ImportDeclarator($2)}

fxn:
  FUN ID LPAREN params RPAREN LBRACE stmts RBRACE{
    {
      fname = $2;
      params = $4;
      body = $7;
    }
  }

params:
	/* */ {[]}
	| expr {[$1]}
  | expr COMMA params {$1::$3}

typ:
  TYPE ID ASSIGN LBRACE parts RBRACE sub_typs {
    {
      tname = $2;
      global_body = $5;
      sub_typs = $7;
    }
  }
  | TYPE ID ASSIGN sub_typs {
    {
      tname = $2;
      global_body = [];
      sub_typs = $4;
    }
  }

sub_typs:
  sub_typ {[$1]}
  | sub_typ VERT sub_typs {$1 :: $3}

sub_typ:
  ID %prec NOOF {
    {
      stname = $1;
      oftyp = None;
      body = [];
    }
  }
  | ID OF exprs %prec NOCOMMA {
    {
      stname = $1;
      oftyp = Some($3);
      body = [];
    }
  }
  | ID LBRACE parts RBRACE {
    {
      stname = $1;
      oftyp = None;
      body = $3;
    }
  }
  | ID OF exprs LBRACE parts RBRACE {
    {
      stname = $1;
      oftyp = Some($3);
      body = $5;
    }
  }

stmts:
  /* */ %prec NOCOMMA {[]}
  | stmt stmts {$1 :: $2}

stmt:
  expr SEMI {Expr($1)}
  | LBRACE stmts RBRACE {Block($2)}
  | typ SEMI {NestedTypeDeclarator($1)}
  | PRINT expr SEMI {Print($2)}
  | RETURN expr SEMI {Return($2)}
  | RAISE expr SEMI{Raise($2)}
  | BREAK SEMI {Break}
  | WHILE LPAREN expr RPAREN LBRACE stmts RBRACE  {Conditional(While($3, $6))}
  | FOR LPAREN expr SEMI expr SEMI expr RPAREN LBRACE stmts RBRACE {Conditional(For($3, $5, $7, $10))}
  | FOR LPAREN expr IN expr RPAREN LBRACE stmts RBRACE {Conditional(ForIn($3, $5, $8))}
  | MATCH LPAREN expr RPAREN LBRACE match_conditions RBRACE{Conditional(Match($3, $6))}
  | TRY LBRACE stmts RBRACE CATCH expr LBRACE stmts RBRACE {Conditional(Try($3, $6, $8))}
  | IF LPAREN expr RPAREN LBRACE stmts RBRACE %prec NOELSE {Conditional(If($3, $6, Else([])))}
  | IF LPAREN expr RPAREN LBRACE stmts RBRACE else_stmt {Conditional(If($3, $6, $8))}
  | SEMI {Empty}

match_conditions:
  match_condition LBRACE stmts RBRACE {[($1, $3)]}
  | match_condition LBRACE stmts RBRACE VERT match_conditions {($1, $3) :: $6}

match_condition:
  expr %prec NOCOMMA {MatchConditional($1, [])}
  | expr LPAREN id RPAREN {MatchConditional($1, [$3])}
  | expr LPAREN ids RPAREN {MatchConditional($1, $3)}
  | expr LPAREN ids RPAREN WHEN expr {WhenMatchConditional($1, $3, $6)}
  | expr LPAREN id RPAREN WHEN expr {WhenMatchConditional($1, [$3], $6)}
  | expr WHEN expr {WhenMatchConditional($1, [], $3)}

else_stmt:
  ELIF LPAREN expr RPAREN LBRACE stmts RBRACE %prec NOELSE {ElIf(If($3, $6, Else([])))}
  | ELIF LPAREN expr RPAREN LBRACE stmts RBRACE else_stmt {ElIf(If($3, $6, $8))}
  | ELSE LBRACE stmts RBRACE {Else($3)}

exprs:
  expr %prec NOCOMMA {[$1]}
  | expr COMMA exprs {$1 :: $3}

expr:
  /*PreOps*/
  DECREMENT expr %prec PREDECREMENT {PrefixOp(PreDecrement, $2)}
  | INCREMENT expr %prec PREDECREMENT {PrefixOp(PreIncrement, $2)}
  | NEGATE expr {PrefixOp(Negate, $2)}
  | MINUS expr %prec UMINUS {PrefixOp(UMinus, $2)}
  | TRY expr COLON expr %prec TRY {TryPrefix($2, $4)}
  /*BinOps*/
  | expr PLUS expr {BinOp($1, Plus, $3)}
  | expr MINUS expr {BinOp($1, Minus, $3)}
  | expr TIMES expr {BinOp($1, Times, $3)}
  | expr DIVIDE expr {BinOp($1, Divide, $3)}
  | expr MOD expr {BinOp($1, Mod, $3)}
  | expr AND expr {BinOp($1, And, $3)}
  | expr OR expr {BinOp($1, Or, $3)}
  | expr LT expr {BinOp($1, Less, $3)}
  | expr GT expr {BinOp($1, Greater, $3)}
  | expr LEQ expr {BinOp($1, LessEqual, $3)}
  | expr GEQ expr {BinOp($1, GreaterEqual, $3)}
  | expr EQ expr {BinOp($1, Equal, $3)}
  | expr NEQ expr {BinOp($1, NotEqual, $3)}
  | expr IS expr {Is($1, $3)}
  | expr QUEST expr COLON expr %prec TERTIARY {TertiaryOp($1, $3, $5)}
  | expr ASSIGN expr {Assign($1, AEq, $3)}
  | expr PLUSASSIGN expr {Assign($1, APlus, $3)}
  | expr MINUSASSIGN expr {Assign($1, AMinus, $3)}
  | expr TIMESASSIGN expr {Assign($1, ATimes, $3)}
  | expr DIVIDEASSIGN expr {Assign($1, ADivide, $3)}
  | expr MODASSIGN expr {Assign($1, AMod, $3)}
  | expr FORCEASSIGN expr {Assign($1, AForce, $3)}
  | LPAREN exprs RPAREN ASSIGN LPAREN exprs RPAREN {MultiAssign($2, AEq, $6)}
  | LPAREN exprs RPAREN PLUSASSIGN LPAREN exprs RPAREN {MultiAssign($2, APlus, $6)}
  | LPAREN exprs RPAREN MINUSASSIGN LPAREN exprs RPAREN {MultiAssign($2, AMinus, $6)}
  | LPAREN exprs RPAREN TIMESASSIGN LPAREN exprs RPAREN {MultiAssign($2, ATimes, $6)}
  | LPAREN exprs RPAREN DIVIDEASSIGN LPAREN exprs RPAREN {MultiAssign($2, ADivide, $6)}
  | LPAREN exprs RPAREN MODASSIGN LPAREN exprs RPAREN {MultiAssign($2, AMod, $6)}
  | LPAREN exprs RPAREN FORCEASSIGN LPAREN exprs RPAREN {MultiAssign($2, AForce, $6)}
  /*PostOps*/
  | id %prec NOCOMMA {Id($1)}
  | literal {Literal($1)}
  | expr brack_exprs {TableAccess($1, $2)}
  | expr paren_tuple_exprs {TupleAccess($1, $2)}
  | expr period_access_exprs {TypeAccess($1, $2)}
  | expr LPAREN RPAREN {Call($1, [])}
  | expr LPAREN exprs RPAREN {Call($1, $3)}
  | expr INCREMENT {PostfixOp($1, PostIncrement)}
  | expr DECREMENT {PostfixOp($1, PostDecrement)}

id:
  ID {StdId($1)}
  | ID QUEST {OptId($1)}
  | ID FORCE {ForceId($1)}
  | UNDER {Discard}
  | LPAREN ids RPAREN {TupleId($2)}

ids:
  id COMMA id {[$1; $3]}
  | id COMMA ids {$1 :: $3}

brack_exprs:
	LBRACK expr RBRACK %prec NOCOMMA {[$2]}
	| LBRACK expr RBRACK brack_exprs {$2 :: $4}

paren_tuple_exprs:
  PERIOD LPAREN INT RPAREN %prec NOCOMMA {[$3]}
  | PERIOD LPAREN INT RPAREN paren_tuple_exprs {$3 :: $5}

period_access_exprs:
  PERIOD expr %prec NOCOMMA {[$2]}
  | PERIOD expr PERIOD period_access_exprs {$2 :: $4}

literal:
  INT {Int($1)}
  | DOUBLE {Double($1)}
  | CHAR {Char($1)}
  | BOOL {Bool($1)}
  | STRING {String($1)}
  | LBRACE RBRACE {Table(EmptyTable)}
  | LBRACE exprs RBRACE {Table(ArrayLiteral($2))}
  | LBRACE key_val_exprs RBRACE {Table(KeyValueLiteral($2))}
  | LPAREN exprs RPAREN {Tuple($2)}

key_val_exprs:
  INT COLON expr {[(IntKey($1), $3)]}
  | STRING COLON expr {[(StringKey($1), $3)]}
  | INT COLON expr COMMA key_val_exprs {(IntKey($1), $3) :: $5}
  | STRING COLON expr COMMA key_val_exprs {(StringKey($1), $3) :: $5}
