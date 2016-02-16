open Fast
open Util

let rec format_stmt = function
  Ast.Expr(e) -> Expr(e)
  | Ast.Block(b) -> Block(format_stmt_list b)
  | Ast.Conditional(c) -> Conditional(format_conditional_stmt c)
  | Ast.TypeDeclarator(n) ->
    let formatted_typ = TypeDeclarator(format_typ n) in
    ignore(Typ(ref formatted_typ) :: scope) ;
    TypeDeclarator(format_typ n)
  | Ast.Print(p) -> Print(p)
  | Ast.Return(r) -> Return(r)
  | Ast.Raise(r) -> Raise(r)
  | Ast.Break -> Break
  | Ast.Empty -> Empty

and format_conditional_stmt = function
  Ast.If(p, s, e) -> If(p, (format_stmt_list s), (format_else_stmt e))
  | Ast.Try(s1, p, s2) -> Try((format_stmt_list s1), p, (format_stmt_list s2))
  | Ast.While(p, s) -> While(p, (format_stmt_list s))
  | Ast.For(p1, p2, p3, s) -> For(p1, p2, p3, (format_stmt_list s))
  | Ast.ForIn(p1, p2, s) -> ForIn(p1, p2, (format_stmt_list s))
  | Ast.Match(p, m) -> Match(p, List.map (fun (mp, s) -> (mp, format_stmt_list s)) m)

and format_else_stmt = function
  Ast.ElIf(e) -> ElIf(format_conditional_stmt e)
  | Ast.Else(e) -> Else(format_stmt_list e)

and format_stmt stmts = List.fold_left (
    fun stmt_list s -> (format_stmt s) :: stmt_list
  ) [] stmts

and format_typ typ = {
  tname = typ.Ast.tname;
  global_typs = format_typs typ.Ast.global_body;
  global_fxns = format_fxns typ.Ast.global_body;
  global_stmts = format_stmts typ.Ast.global_body;
  sub_typs = List.map format_sub_typ typ.Ast.sub_typs;
}

and format_sub_typ sub_typ = {
  stname = sub_typ.Ast.stname;
  oftyp = sub_typ.Ast.oftyp;
  nested_typs = format_typs sub_typ.Ast.body;
  nested_fxns = format_fxns sub_typ.Ast.body;
  nested_stmts = format_stmts sub_typ.Ast.body;
}

and format_fxn fxn = {
  fname = fxn.Ast.fname;
  params = fxn.Ast.params;
  body = format_stmt_list fxn.Ast.body;
}

and format_fxns parts = List.fold_left (
  fun fxns t ->
    match t with
      Ast.Fxn(mf) -> (format_fxn mf) :: fxns
      | _ -> fxns
  ) [] parts

let format_program (imports, parts) =
  let formatted_stmts = format_stmts (filter_stmts parts) in {
    imports = imports;
    stmts = formatted_stmts;
    scope =
    (List.map (fun f -> Fxn(ref f)) filter_fxns parts) ::
    (List.map (fun t -> Typ(ref t)) filter_typs formatted_stmts);
  }
