type stmt_f =
  Expr of Ast.expr
  | Block of (stmt_f list)
  | Conditional of conditional_stmt_f
  | NestedTypeDeclarator of typ_f
  | Print of Ast.expr
  | Return of Ast.expr
  | Raise of Ast.expr
  | Break
  | Empty
and conditional_stmt_f =
  If of Ast.expr * (stmt_f list) * else_stmt_f
  | Try of (stmt_f list) * Ast.expr * (stmt_f list)
  | While of Ast.expr * (stmt_f list)
  | For of Ast.expr * Ast.expr * Ast.expr * (stmt_f list)
  | ForIn of Ast.expr * Ast.expr * (stmt_f list)
  | Match of Ast.expr * ((Ast.match_conditional * (stmt_f list)) list)
and else_stmt_f =
  ElIf of conditional_stmt_f
  | Else of (stmt_f list)
and fxn_f = {
  fname : string;
	params : (Ast.expr list);
	body : (stmt_f list);
}
and typ_f = {
  tname: string;
  global_typs: typ_f list;
  global_fxns: fxn_f list;
  global_stmts: stmt_f list;
  sub_typs: sub_typ_f list
}
and sub_typ_f = {
  stname: string;
  oftyp: Ast.expr list option;
  nested_typs: typ_f list;
  nested_fxns: fxn_f list;
  nested_stmts: stmt_f list;
}

type program_f = {
  imports: Ast.import list;
  mutable fxns: fxn_f list;
  mutable typs: typ_f list;
  mutable stmts: stmt_f list;
}
