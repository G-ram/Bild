type bin_op = Plus | Minus | Times | Divide | Mod
              | And | Or | Less | Greater
              | LessEqual | GreaterEqual | Equal | NotEqual

type assign_op = APlus | AMinus | ATimes | ADivide | AMod |AEq

type post_op = Force | PostIncrement | PostDecrement

type pre_op = PreIncrement | PreDecrement | UMinus | Negate

type key_literal =
	IntKey of int
	| StringKey of string

type literal =
  Int of int
  | Double of float
  | String of string
  | Char of char
  | Bool of bool
  | Table of table_literal
  | Tuple of (expr list)
and table_literal =
  EmptyTable
  | ArrayLiteral of expr list
  | KeyValueLiteral of (key_literal * expr) list
and expr =
  Prefix of pre_expr * (bin_expr list)
and pre_expr =
  PrefixOp of pre_op * post_expr
  | Postfix of post_expr
  | TryPrefix of pre_expr * pre_expr
and post_expr =
  Discard
  | Id of string
  | OptId of string
  | Literal of literal
  | TupleId of (post_expr list)
  | TableAccess of post_expr * (expr list)
  | TupleAccess of post_expr * (expr list)
  | Call of post_expr * (expr list)
  | TypeCall of post_expr * string * (expr list)
  | PostfixOp of post_expr * post_op
  | Paran of expr
and bin_expr =
  BinOp of bin_op * pre_expr
  | Assign of assign_op * pre_expr
  | TertiaryOp of expr * pre_expr
  | Is of pre_expr

type stmt =
  Expr of expr
  | Block of (stmt list)
  | Conditional of conditional_stmt
  | NestedTypeDeclarator of typ
  | Print of expr
  | Return of expr
  | Raise of expr
  | Break
  | Empty
and conditional_stmt =
  If of expr * (stmt list) * else_stmt
  | Try of (stmt list) * expr * (stmt list)
  | While of expr * (stmt list)
  | For of expr * expr * expr * (stmt list)
  | ForIn of post_expr * expr * (stmt list)
  | Match of expr * ((match_conditional * (stmt list)) list)
and else_stmt =
  ElIf of conditional_stmt
  | Else of (stmt list)
and match_conditional =
  MatchConditional of post_expr * (post_expr list)
  | WhenMatchConditional of post_expr * (post_expr list) * expr
and fxn = {
  fname : string;
	params : (post_expr list);
	body : (stmt list);
}
and typ = {
    tname: string;
    global_body: (part list);
    sub_typs: (sub_typ list)
}
and sub_typ = {
    stname: string;
    oftyp: expr option;
    body: (part list)
}
and part =
  Fxn of fxn
  | Typ of typ
  | Stmt of stmt

type import = ImportDeclarator of string

type program = (import list) * (part list)
