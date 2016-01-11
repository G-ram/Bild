%{
  open Ast
%}

%token LPAREN RPAREN LBRACE RBRACE LBRACK RBRACK
%token PLUS MINUS TIMES DIVIDE MOD
%token INCREMENT DECREMENT
%token LT GT LEQ GEQ EQ NEQ AND OR
%token FORCE QUEST
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
%token <string> ID
%token <string> OPTID
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
%left TERTIARY TRY
%left PLUS MINUS
%left TIMES DIVIDES MOD
%nonassoc UMINUS
%nonassoc NEGATE
%nonassoc PREDECREMENT

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
	| post_expr {[$1]}
  | post_expr COMMA params {$1::$3}

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
  | ID OF expr %prec NOCOMMA {
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
  | ID OF expr LBRACE parts RBRACE {
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
  | FOR LPAREN post_expr IN expr RPAREN LBRACE stmts RBRACE {Conditional(ForIn($3, $5, $8))}
  | MATCH LPAREN expr RPAREN LBRACE match_conditions RBRACE{Conditional(Match($3, $6))}
  | TRY LBRACE stmts RBRACE CATCH expr LBRACE stmts RBRACE {Conditional(Try($3, $6, $8))}
  | IF LPAREN expr RPAREN LBRACE stmts RBRACE %prec NOELSE {Conditional(If($3, $6, Else([])))}
  | IF LPAREN expr RPAREN LBRACE stmts RBRACE else_stmt {Conditional(If($3, $6, $8))}
  | SEMI {Empty}

match_conditions:
  match_condition LBRACE stmts RBRACE {[($1, $3)]}
  | match_condition LBRACE stmts RBRACE VERT match_conditions {($1, $3) :: $6}

match_condition:
  post_expr %prec NOCOMMA {MatchConditional($1, [])}
  | post_expr LPAREN opt_typs RPAREN {MatchConditional($1, $3)}
  | post_expr LPAREN opt_typs RPAREN WHEN expr {WhenMatchConditional($1, $3, $6)}
  | post_expr WHEN expr {WhenMatchConditional($1, [], $3)}

else_stmt:
  ELIF LPAREN expr RPAREN LBRACE stmts RBRACE %prec NOELSE {ElIf(If($3, $6, Else([])))}
  | ELIF LPAREN expr RPAREN LBRACE stmts RBRACE else_stmt {ElIf(If($3, $6, $8))}
  | ELSE LBRACE stmts RBRACE {Else($3)}

exprs:
  expr %prec NOCOMMA {[$1]}
  | expr COMMA exprs {$1 :: $3}

expr:
  pre_expr bin_exprs {Prefix($1, $2)}

pre_expr:
  DECREMENT post_expr %prec PREDECREMENT {PrefixOp(PreDecrement, $2)}
  | INCREMENT post_expr %prec PREDECREMENT {PrefixOp(PreIncrement, $2)}
  | FORCE %prec NEGATE post_expr {PrefixOp(Negate, $2)}
  | MINUS post_expr %prec UMINUS {PrefixOp(UMinus, $2)}
  | TRY pre_expr COLON pre_expr {TryPrefix($2, $4)}
  | post_expr %prec NOCOMMA {Postfix($1)}

bin_exprs:
  /* */ %prec NOCOMMA {[]}
  | bin_expr bin_exprs {$1 :: $2}

bin_expr:
  PLUS pre_expr {BinOp(Plus, $2)}
  | MINUS pre_expr {BinOp(Minus, $2)}
  | TIMES pre_expr {BinOp(Times, $2)}
  | DIVIDE pre_expr {BinOp(Divide, $2)}
  | MOD pre_expr {BinOp(Mod, $2)}
  | AND pre_expr {BinOp(And, $2)}
  | OR pre_expr {BinOp(Or, $2)}
  | LT pre_expr {BinOp(Less, $2)}
  | GT pre_expr {BinOp(Greater, $2)}
  | LEQ pre_expr {BinOp(LessEqual, $2)}
  | GEQ pre_expr {BinOp(GreaterEqual, $2)}
  | EQ pre_expr {BinOp(Equal, $2)}
  | NEQ pre_expr {BinOp(NotEqual, $2)}
  | IS pre_expr {Is($2)}
  | QUEST expr COLON pre_expr {TertiaryOp($2, $4)}
  | ASSIGN pre_expr {Assign(AEq, $2)}
  | PLUSASSIGN pre_expr {Assign(APlus, $2)}
  | MINUSASSIGN pre_expr {Assign(AMinus, $2)}
  | TIMESASSIGN pre_expr {Assign(ATimes, $2)}
  | DIVIDEASSIGN pre_expr {Assign(ADivide, $2)}
  | MODASSIGN pre_expr {Assign(AMod, $2)}

post_expr:
  opt_typ %prec NOCOMMA {$1}
  | literal {Literal($1)}
  | LPAREN opt_typs RPAREN {TupleId($2)}
  | post_expr brack_exprs {TableAccess($1, $2)}
  | post_expr paren_tuple_exprs {TupleAccess($1, $2)}
  | post_expr LPAREN RPAREN {Call($1, [])}
  | post_expr LPAREN exprs RPAREN {Call($1, $3)}
  | post_expr PERIOD ID LPAREN RPAREN {TypeCall($1, $3, [])}
  | post_expr PERIOD ID LPAREN exprs RPAREN {TypeCall($1, $3, $5)}
  | post_expr INCREMENT {PostfixOp($1, PostIncrement)}
  | post_expr DECREMENT {PostfixOp($1, PostDecrement)}
  | post_expr FORCE {PostfixOp($1, Force)}
  | LPAREN expr RPAREN {Paran($2)}

opt_typ:
  ID {Id($1)}
  | OPTID {OptId($1)}
  | UNDER {Discard}

opt_typs:
  opt_typ COMMA opt_typ {[$1; $3]}
  | opt_typ COMMA opt_typs {$1 :: $3}

brack_exprs:
	LBRACK expr RBRACK %prec NOCOMMA {[$2]}
	| LBRACK expr RBRACK brack_exprs {$2 :: $4}

paren_tuple_exprs:
  PERIOD LPAREN expr RPAREN %prec NOCOMMA {[$3]}
  | PERIOD LPAREN expr RPAREN paren_tuple_exprs {$3 :: $5}

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
