{
  open Parser
  let wrap_id str = "_" ^ str ^ "_"
  (*Inline*)
  let inline = ref false
  let end_inline = ref 1
  (*Keep track of line numbers*)
  let valid_line = ref 1
  let line_num = ref 1
  exception Syntax_error of string
  let syntax_error msg = raise (Syntax_error (msg ^ " on line " ^ (string_of_int !line_num)))
  (*Return the character of string*)
  let strip_both_chars str = match String.length str with
    0 | 1 | 2 -> ""
    | len -> String.sub str 1 (len - 2)
}
let digits = ['0' - '9']+
let signed_int = ['+' '-']? digits
let decimal = ['+' '-']? (digits '.' ['0'-'9']* | '.' digits) (['e' 'E'] signed_int)?
let id = ['a'-'z' 'A'-'Z']['a'-'z' 'A'-'Z' '0'-'9' '_']*

rule token pat = parse
  [' ' '\t'] {token pat lexbuf}
  | ['\r' '\n'] {incr line_num; token pat lexbuf}
	| "/*" {multi_comment pat lexbuf}
  | "//" {line_comment pat lexbuf}
	| '[' {LBRACK} | ']' {RBRACK}
	| '{' {LBRACE} | '}' {RBRACE}
	| '(' {LPAREN} | ')' {RPAREN}
	| ';' {SEMI} | ':' {COLON}
	| ',' {COMMA} | '.' {PERIOD} | '|' {VERT}
  | "fun" {FUN} | "print" {PRINT} | "inline" {pat := true ; INLINE}
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
  | '?' {QUEST} | '!' {NEGATE} | '_' {UNDER}
	| '<' {LT} | '>' {GT} | "==" {EQ} | "!=" {NEQ} | ">=" {GEQ} | "<=" {LEQ} | "&&" {AND} | "||" {OR}
	| '+' {PLUS} | '-' {MINUS} | '*' {TIMES} | '/' {DIVIDE} | '%' {MOD} | '!' {FORCE}
  | "++" {INCREMENT} | "--" {DECREMENT}
  | '=' {ASSIGN} | "+=" {PLUSASSIGN} | "-=" {MINUSASSIGN} | "*=" {TIMESASSIGN} | "/=" {DIVIDEASSIGN} | "%=" {MODASSIGN} | "!=" {FORCEASSIGN}
  | id as lxm {ID(wrap_id lxm)}
	| digits as lxm {INT(int_of_string lxm)}
	| decimal as lxm {DOUBLE(float_of_string lxm)}
	| '"' [^ '"']* '"' as lxm {STRING(lxm)}
  | '\'' [^ '\''] '\'' as lxm {CHAR((strip_both_chars lxm).[0])}
  | _ { syntax_error "couldn't identify the token" }
	| eof {EOF}
  and multi_comment pat = parse
	"*/" {token pat lexbuf}
	| _    {multi_comment pat lexbuf}
  and line_comment pat = parse
  ['\r' '\n'] {token pat lexbuf}
	| _    {line_comment pat lexbuf}

and inline_scan pat = parse
  | "{" {end_inline := !end_inline + 1 ; CPP_STRING("{")}
  | "}" {
    match (!end_inline - 1) with
    0 -> end_inline := 1 ; RBRACK
    | _ -> end_inline := !end_inline - 1 ; pat := false ; CPP_STRING("}")
  }
  | _ as lxm {CPP_STRING("" ^ Char.escaped lxm)}

{
  let next_token lexbuf = match !inline with
    | true -> inline_scan inline lexbuf
    | false -> token inline lexbuf
}
