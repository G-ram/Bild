open Fast
open Util

let rec format_stmt = function
  Ast.Expr(e) -> Expr(e)
  | Ast.Block(b) -> Block(format_stmts b)
  | Ast.Conditional(c) -> Conditional(format_conditional_stmt c)
  | Ast.Inline(i) -> Inline(i)
  | Ast.TypeDeclarator(t) -> TypeDeclarator(format_typ t)
  | Ast.FxnDeclarator(f) -> FxnDeclarator(format_fxn f)
  | Ast.Print(p) -> Print(p)
  | Ast.Return(r) -> Return(r)
  | Ast.Raise(r) -> Raise(r)
  | Ast.Break -> Break
  | Ast.Empty -> Empty

and format_conditional_stmt = function
  Ast.If(p, s, e) -> If(p, (format_stmts s), (format_else_stmt e))
  | Ast.Try(s1, p, s2) -> Try((format_stmts s1), p, (format_stmts s2))
  | Ast.While(p, s) -> While(p, (format_stmts s))
  | Ast.For(p1, p2, p3, s) -> For(p1, p2, p3, (format_stmts s))
  | Ast.ForIn(p1, p2, s) -> ForIn(p1, p2, (format_stmts s))
  | Ast.Match(p, m) -> Match(p, List.map (fun (mp, s) -> (mp, format_stmts s)) m)

and format_else_stmt = function
  Ast.ElIf(e) -> ElIf(format_conditional_stmt e)
  | Ast.Else(e) -> Else(format_stmts e)

and format_stmts stmts = List.fold_left (
    fun stmt_list s -> (format_stmt s) :: stmt_list
  ) [] stmts

and format_typ typ =
  let formatted_stmts = format_stmts typ.Ast.body in {
    name = typ.Ast.name;
    stmts = formatted_stmts;
    sub_typs = List.map format_sub_typ typ.Ast.sub_typs;
    scope = build_scope formatted_stmts;
  }

and format_sub_typ sub_typ =
  let formatted_stmts = format_stmts sub_typ.Ast.body in {
    name = sub_typ.Ast.name;
    oftyp = sub_typ.Ast.oftyp;
    stmts = formatted_stmts;
    scope = build_scope formatted_stmts;
  }

and format_fxn fxn =
  let formatted_stmts = format_stmts fxn.Ast.body in {
    name = fxn.Ast.name;
    params = fxn.Ast.params;
    body = formatted_stmts;
    scope = build_scope formatted_stmts;
  }

let format_program (imports, stmts) =
  let formatted_stmts = format_stmts stmts in {
    imports = imports;
    stmts = formatted_stmts;
    scope = build_scope formatted_stmts;
  }
