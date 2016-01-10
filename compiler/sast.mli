type t = Int | Double | Char | String | Bool
        | Table of t option | Tuple of (t list)
        | Custom of string * (t option)

type expr_t = pre_expr_t * (bin_expr_t list) * t
and pre_expr_t =
  PrefixOp of Ast.pre_op * post_expr_t
  | Postfix of post_expr_t
  | TryPrefix of pre_expr_t * pre_expr_t
and post_expr_t =
  Discard
  | Id of string
  | OptId of string
  | Literal of Ast.literal
  | TupleId of (post_expr_t list)
  | TableAccess of post_expr_t * (expr_t list)
  | TupleAccess of post_expr_t * (expr_t list)
  | Call of post_expr_t * (expr_t list)
  | TypeCall of post_expr_t * string * (expr_t list)
  | PostfixOp of post_expr_t * Ast.post_op
  | Paran of expr_t
and bin_expr_t =
  BinOp of Ast.bin_op * pre_expr_t
  | Assign of Ast.assign_op * pre_expr_t
  | TertiaryOp of expr_t * pre_expr_t
  | Is of pre_expr_t

type stmt_t =
  Expr of expr_t
  | Block of (stmt_t list)
  | Conditional of conditional_stmt_t
  | NestedTypeDeclarator of typ_t
  | Print of expr_t
  | Return of expr_t
  | Raise of expr_t
  | Break
  | Empty
  and conditional_stmt_t =
  If of expr_t * (stmt_t list) * else_stmt_t
  | Try of (stmt_t list) * expr_t * (stmt_t list)
  | While of expr_t * (stmt_t list)
  | For of expr_t * expr_t * expr_t * (stmt_t list)
  | ForIn of post_expr_t * expr_t * (stmt_t list)
  | Match of expr_t * ((match_conditional_t * (stmt_t list)) list)
  and else_stmt_t =
  ElIf of conditional_stmt_t
  | Else of (stmt_t list)
  and match_conditional_t =
  MatchConditional of post_expr_t * (post_expr_t list)
  | WhenMatchConditional of post_expr_t * (post_expr_t list) * expr_t
and typ_t = {
  typ: t;
  global_body: (stmt_t list);
  sub_typs: sub_typ_t list
}
and sub_typ_t = {
  name: string;
  typ: t;
  oftyp: expr_t option;
  nested_typs: typ_t list;
  nested_fxns: fxn_t list;
  nested_stmts: stmt_t list;
}
and fxn_t = {
  name: string;
  params: Ast.post_expr list;
  body: stmt_t list;
  return: t option;
  returns: (stmt_t ref) list
}

type symbol_table = {
  parent: symbol_table option;
  mutable variables: (string * t ref) list;
}

type translation_environment = {
  scope: symbol_table;
  mutable typs: typ_t list
}

type program_t = {
  imports: Ast.import list;
  mutable fxns: fxn_t list;
  mutable typs: typ_t list;
  mutable stmts: stmt_t list;
}
