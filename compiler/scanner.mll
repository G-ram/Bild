{
  open Parser
  let wrap_id str = "_" ^ str ^ "_"
  (*Keep track of line numbers*)
  let valid_line = ref 1
  let line_num = ref 1
  exception Syntax_error of string
  let syntax_error msg = raise (Syntax_error (msg ^ " on line " ^ (string_of_int !line_num)))
  let strip_both_chars str = match String.length str with
    0 | 1 | 2 -> ""
    | len -> String.sub str 1 (len - 2)
}
let digits = ['0' - '9']+
let signed_int = ['+' '-']? digits
let decimal = ['+' '-']? (digits '.' ['0'-'9']* | '.' digits) (['e' 'E'] signed_int)?
let id = ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']*
let opt_id = ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']*'?'

rule token = parse
  [' ' '\t'] {token lexbuf}
  | ['\r' '\n'] {incr line_num; token lexbuf}
	| "/*" {multi_comment lexbuf}
  | "//" {line_comment lexbuf}
	| '[' {LBRACK} | ']' {RBRACK}
	| '{' {LBRACE} | '}' {RBRACE}
	| '(' {LPAREN} | ')' {RPAREN}
	| ';' {SEMI} | ':' {COLON}
	| ',' {COMMA} | '.' {PERIOD} | '|' {VERT}
  | "fun" {FUN} | "print" {PRINT}
	| "in" {IN}
  | "true" {BOOL(true)} | "false" {BOOL(false)}
  | "else" {ELSE} | "if" {IF} | "elif" {ELIF}
  | "while" {WHILE} | "for" {FOR}
  | "match" {MATCH} | "when" {WHEN}
	| "break" {BREAK} | "return" {RETURN} | "raise" {RAISE}
  | "try" {TRY} | "catch" {CATCH}
  | "type" {TYPE}
  | "import" {IMPORT}
  | "of" {OF} | "is" {IS}
  | '?' {QUEST} | '!' {FORCE} | '_' {UNDER}
	| '<' {LT} | '>' {GT} | "==" {EQ} | "!=" {NEQ} | ">=" {GEQ} | "<=" {LEQ} | "&&" {AND} | "||" {OR}
	| '+' {PLUS} | '-' {MINUS} | '*' {TIMES} | '/' {DIVIDE} | '%' {MOD}
  | "++" {INCREMENT} | "--" {DECREMENT}
  | '=' {ASSIGN} | "+=" {PLUSASSIGN} | "-=" {MINUSASSIGN} | "*=" {TIMESASSIGN} | "/=" {DIVIDEASSIGN} | "%=" {MODASSIGN} | "!=" {FORCEASSIGN}
  | opt_id as lxm{ID(wrap_id lxm)}
  | id as lxm {ID(wrap_id lxm)}
	| digits as lxm {INT(int_of_string lxm)}
	| decimal as lxm {DOUBLE(float_of_string lxm)}
	| '"' [^ '"']* '"' as lxm {STRING(lxm)}
  | '\'' [^ '\''] '\'' as lxm {CHAR((strip_both_chars lxm).[0])}
  | _ { syntax_error "couldn't identify the token" }
	| eof {EOF}
  and multi_comment = parse
	"*/" {token lexbuf}
	| _    {multi_comment lexbuf}
  and line_comment = parse
  ['\r' '\n'] {token lexbuf}
	| _    {line_comment lexbuf}
