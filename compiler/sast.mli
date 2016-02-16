type t = Int | Double | Char | String | Bool
        | Table of t | Tuple of (t list)
        | Custom of string * (t option)
        | Opt of t | Func of t | Void

(* Add expressions*)
type expr_t = expr_det * t
and expr_det =
  PrefixOp of Ast.pre_op * expr_t
  | TryPrefix of expr_t * expr_t
  | Id of Ast.id
  | Literal of Ast.literal
  | TableAccess of expr_t * (expr_t list)
  | TupleAccess of expr_t * (int list)
  | TypeAccess of expr_t * (expr_t list)
  | Call of expr_t * (expr_t list)
  | PostfixOp of expr_t * Ast.post_op
  | BinOp of expr_t * Ast.bin_op * expr_t
  | Assign of expr_t * Ast.assign_op * expr_t
  | VAssign of expr_t * Ast.assign_op * expr_t
  | MultiAssign of expr_t list
  | TertiaryOp of expr_t * expr_t * expr_t
  | Is of expr_t * expr_t

type stmt_t =
  Expr of expr_t
  | Block of (stmt_t list)
  | Conditional of conditional_stmt_t
  | TypeDeclarator of typ_t
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
  | ForIn of expr_t * expr_t * (stmt_t list)
  | Match of expr_t * ((match_conditional_t * (stmt_t list)) list)
  and else_stmt_t =
  ElIf of conditional_stmt_t
  | Else of (stmt_t list)
  and match_conditional_t =
  MatchConditional of expr_t * expr_t
  | WhenMatchConditional of expr_t * expr_t * expr_t
and typ_t = {
  tname: string;
  global_typs: typ_t list;
  global_fxns: fxn_t list;
  global_stmts: stmt_t list;
  sub_typs: sub_typ_t list
}
and sub_typ_t = {
  typ: t;
  nested_typs: typ_t list;
  nested_fxns: fxn_t list;
  nested_stmts: stmt_t list;
}
and fxn_t = {
  fname: string;
  params: Ast.id list;
  body: stmt_t list;
  return: t ref option;
  returns: (stmt_t ref) list
}

type variable =
  RegTyp of string * t
  | FxnTyp of string * t
  | TypeTyp of string * t * (symbol_table ref option)
and symbol_table = {
  parent: symbol_table option;
  mutable variables: variable list;
}

type program_t = {
  imports: Ast.import list;
  mutable fxns: fxn_t list;
  mutable typs: typ_t list;
  mutable stmts: stmt_t list;
}
