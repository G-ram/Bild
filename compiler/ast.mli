type bin_op = Plus | Minus | Times | Divide | Mod
              | And | Or | Less | Greater
              | LessEqual | GreaterEqual | Equal | NotEqual

type assign_op = APlus | AMinus | ATimes | ADivide | AMod | AEq | AForce

type post_op = PostIncrement | PostDecrement

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
and id =
  StdId of string
  | OptId of string
  | ForceId of string
  | TupleId of id list
  | Discard
and expr =
  PrefixOp of pre_op * expr
  | TryPrefix of expr * expr
  | Id of id
  | Literal of literal
  | TableAccess of expr * (expr list)
  | TupleAccess of expr * (int list)
  | TypeAccess of expr * (expr list)
  | Call of expr * (expr list)
  | PostfixOp of expr * post_op
  | BinOp of expr * bin_op * expr
  | Assign of expr * assign_op * expr
  | MultiAssign of (expr list) * assign_op * (expr list)
  | TertiaryOp of expr * expr * expr
  | Is of expr * expr

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
  | ForIn of expr * expr * (stmt list)
  | Match of expr * ((match_conditional * (stmt list)) list)
and else_stmt =
  ElIf of conditional_stmt
  | Else of (stmt list)
and match_conditional =
  MatchConditional of expr * (id list)
  | WhenMatchConditional of expr * (id list) * expr
and fxn = {
  fname : string;
	params : (expr list);
	body : (stmt list);
}
and typ = {
    tname: string;
    global_body: (part list);
    sub_typs: (sub_typ list)
}
and sub_typ = {
    stname: string;
    oftyp: (expr list) option;
    body: (part list)
}
and part =
  Fxn of fxn
  | Typ of typ
  | Stmt of stmt

type import = ImportDeclarator of string

type program = (import list) * (part list)
