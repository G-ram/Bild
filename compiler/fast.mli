type stmt_f =
  Expr of Ast.expr
  | Block of (stmt_f list)
  | Conditional of conditional_stmt_f
  | Inline of string
  | TypeDeclarator of typ_f
  | FxnDeclarator of fxn_f
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
and t_f =
  Fxn of stmt_f ref
  | Typ of stmt_f ref
and fxn_f = {
  name : string;
	params : (Ast.id list);
	body : (stmt_f list);
  scope: t_f list;
}
and typ_f = {
  name: string;
  stmts: stmt_f list;
  sub_typs: sub_typ_f list;
  scope: t_f list;
}
and sub_typ_f = {
  name: string;
  oftyp: Ast.expr list option; (*May need to add to symbol table*)
  stmts: stmt_f list;
  scope: t_f list;
}

type program_f = {
  imports: Ast.import list;
  mutable stmts: stmt_f list;
  mutable scope: t_f list;
}
