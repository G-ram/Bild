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
  TryPrefix of pre_expr * (bin_expr list) * expr
  | Prefix of pre_expr * (bin_expr list)
and pre_expr =
  PrefixOp of pre_op * post_expr
  | Postfix of post_expr
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
  | TertiaryOp of expr * expr
  | Is of pre_expr

type stmt =
  Expr of expr
  | Block of (stmt list)
  | Conditional of conditional_stmt
  | NestedTypeDeclarator of declarator
  | Print of expr
  | Return of expr
  | Raise of expr
  | Break
  | Empty
and conditional_stmt =
  If of expr * stmt * else_stmt
  | Try of stmt * expr * stmt
  | While of expr * stmt
  | For of expr * expr * expr * stmt
  | ForIn of post_expr * expr * stmt
  | Match of expr * ((match_conditional * stmt) list)
and else_stmt =
  ElIf of conditional_stmt
  | Else of stmt
and match_conditional =
  MatchConditional of post_expr * (post_expr list)
  | WhenMatchConditional of post_expr * (post_expr list) * expr
and declarator =
  FxnDeclarator of fxn
  | ImportDeclarator of string
  | TypeDeclarator of typ
and fxn = {
  name : string;
	params : (post_expr list);
	body : stmt;
}
and typ =
  TypeNoGlobal of typ_no_global
  | Type of reg_typ
and typ_no_global = {
    name: string;
    sub_typs: (sub_typ list)
}
and reg_typ = {
  name: string;
  global_body: (part list);
  sub_typs: (sub_typ list)
}
and sub_typ =
  Enum of string
  | EnumType of string * post_expr
  | NoInherit of string * (part list)
  | Inherit of string * post_expr * (part list)
and part =
  Imports of (declarator list)
  | Fxns of (declarator list)
  | Typs of (declarator list)
  | Stmts of (stmt list)

type program = Program of (part list)
