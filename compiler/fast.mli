type stmt_f =
  Expr of Ast.expr
  | Block of (stmt_f list)
  | Conditional of conditional_stmt_f
  | TypeDeclarator of typ_f
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
and t_f = Func of fxn_f ref
            | Typ of typ_f ref
and symbol_table_f = SymbolTable of t_f list
and fxn_f = {
  fname : string;
	params : (Ast.id list);
	body : (stmt_f list);
  scope: symbol_table_f;
}
and typ_f = {
  tname: string;
  global_scope: symbol_table_f;
  global_stmts: stmt_f list;
  sub_typs: sub_typ_f list;
}
and sub_typ_f = {
  stname: string;
  oftyp: Ast.expr list option; (*May need to add to symbol table*)
  nested_stmts: stmt_f list;
  scope: symbol_table_f;
}

type program_f = {
  imports: Ast.import list;
  mutable stmts: stmt_f list;
  mutable scope: symbol_table_f;
}
