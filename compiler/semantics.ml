open Sast
open Util

let rec check_literal = function
  Ast.Int(i) -> Int
  | Ast.Double(d) -> Double
  | Ast.String(s) -> String
  | Ast.Char(c) -> Char
  | Ast.Bool(b) -> Bool
  | Ast.Table(t) -> Bool (*Work Here*)
  | Ast.Tuple(t) -> Tuple(check_expr_typs t scope program)

and check_expr_typs exprs = List.map (fun e -> snd(check_expr e)) exprs

and check_expr = function
  Ast.PrefixOp(op, e) ->
    let (e, typ) = check_expr e in
    (match typ with
       _ when (op = Ast.PreIncrement || op = Ast.PreDecrement || op = Ast.UMinus) && is_arith typ ->   PrefixOp(op, (e, typ)), typ
      | Bool when op = Ast.Negate -> PrefixOp(op, (e, typ)), typ
      | _ -> raise(Failure("prefix expression has invalid type"))
    )
  | Ast.TryPrefix(e1, e2) ->
    let (e1, typ1) = check_expr e1 in
    let (e2, typ2) = check_expr e2 in
    (match typ1 with
      Opt(t) -> TryPrefix((e1, typ1), (e2, typ2)), (is_typ_same t typ2)
      | _ -> raise(Failure("try expression is only valid for optional types"))
    )
  | Ast.Id(v) -> (*Work Here*)
    let vdecl = try
      find_var_and_scope scope (hash_id v)
    with Not_found ->
      raise (Failure("undeclared identifier " ^ v)) in
    let (v, typ) = vdecl in
    Id(v), typ
  | Ast.Literal(l) -> Literal(l), (check_literal l )
  | Ast.TableAccess(e, el) -> Literal(Ast.Int(5)), Int(*Work Here*)
  | Ast.TupleAccess(e, el) -> Literal(Ast.Int(5)), Int(*Work Here*)
  | Ast.TypeAccess(e, el) -> Literal(Ast.Int(5)), Int(*Work Here*)
  | Ast.Call(e, el) -> Literal(Ast.Int(5)), Int(*Work Here*)
  | Ast.PostfixOp(e, op) ->
    let (e, typ) = check_expr e in
    (match op with
      Ast.PostIncrement when is_arith typ ->
        PostfixOp((e, typ), op), typ
      | Ast.PostDecrement when is_arith typ ->
        PostfixOp((e, typ), op), typ
      | _ -> raise(Failure("postfix expression has invalid type"))
    )
  | Ast.BinOp(e1, op, e2) ->
    let (e1, typ1) = check_expr e1 in
    let (e2, typ2) = check_expr e2 in
    (match op with
      Ast.Plus -> BinOp((e1, typ1), op, (e2, typ2)), (is_cast typ1 typ2)
      | _ when is_arith typ1 && is_arith typ2 -> BinOp((e1, typ1), op, (e2, typ2)), (is_cast typ1 typ2)
      | _ -> raise(Failure("binary expression has invalid type(s)"))
    )
  | Ast.Assign(v, op, e) ->
    let (e, typ) = check_expr e in
    (match (is_assignable v), v, e with
      true, Ast.Id(id), _ -> (
          try
            let (v, vtyp) = find_var_and_scope scope (hash_id id) in
            Assign((v, vtyp), op, (e, typ)), is_typ_same typ vtyp
          with Not_found ->
            ignore(scope.variables <- (RegTyp(hash_id id, typ):: scope.variables)) ;
            VAssign((v, typ), op, (e, typ)), typ
        )
      | true, t, _ -> let (v, vtyp) = check_expr t in
        Assign((v vtyp), op, (e, typ)), is_typ_same typ vtyp
      | _, _, _ -> raise(Failure("type is not assignable; found value, not variable"))
    )
  | Ast.MultiAssign(el2, op, el2) ->
    let typs = [] in
    let el = List.map2 (fun e1 e2 ->
        let (e, typ) = check_expr Ast.Assign(e1, op, e2) in ignore(typ :: typs) ; (e, typ)
      ) el1 el2 in
    MultiAssign(el), Tuple(typs)
  | Ast.TertiaryOp(e1, e2, e3) ->
    let (e1, typ1) = check_expr e1 in
    let (e2, typ2) = check_expr e2 in
    let (e3, typ3) = check_expr e3 in
    (match is_arith typ1 with
      true -> TertiaryOp((e1, typ1), (e2, typ2), (e3, typ3)), (is_typ_same typ2 typ3)
      | _ -> raise(Failure("predicate is not valid bool type"))
    )
  | Ast.Is(e1, e2) ->
    let (e1, typ1) = check_expr e1 in
    let (e2, typ2) = check_expr e2 in
    TryPrefix((e1, typ1), (e2, typ2)), (is_typ_same typ1 typ2)
  | Ast.Discard -> Discard, Void

let rec check_stmt = function
  Fast.Expr(e) -> Expr(check_expr e)
  | Fast.Block(sl) -> Block(check_stmt_list sl)
  | Fast.Conditional(s) -> Conditional(check_conditional_stmt s)
  | Fast.NestedTypeDeclarator(t) -> Empty (*Work Here*)
  | Fast.Print(e) -> Print(check_expr e)
  | Fast.Return(e) -> Return(check_expr e)
  | Fast.Raise(e) -> Raise(check_expr e)
  | Fast.Break -> Break
  | Fast.Empty -> Empty
and check_stmt_list sl = List.map (fun s -> check_stmt s) sl
and check_conditional_stmt = function
  Fast.If(e, sl, el) -> If(check_expr e, check_stmt_list sl, check_else_stmt el)
  | Fast.Try(sl1, e, sl2) -> Try(check_stmt_list sl1, check_expr e, check_stmt_list sl2)
  | Fast.While(e, sl) -> While(check_expr e, check_stmt_list sl)
  | Fast.For(e1, e2, e3, sl) -> For(check_expr e1, check_expr e2, check_expr e3, check_stmt_list sl)
  | Fast.ForIn(e1, e2, sl) -> ForIn(check_expr e1, check_expr e2, check_stmt_list sl)
  | Fast.Match(e, msl) -> Match(check_expr e, List.map (fun (m, sl) -> (check_match_conditional m, check_stmt_list sl)) msl)
and check_else_stmt = function
  Fast.ElIf(s) -> ElIf(check_conditional_stmt s)
  | Fast.Else(sl) -> Else(check_stmt_list sl)
and check_match_conditional = function
  Ast.MatchConditional(e, el) -> MatchConditional(check_expr e, check_expr Ast.TupleId(el))
  | Ast.WhenMatchConditional(e1, el, e2) -> WhenMatchConditional(check_expr e1, check_expr Ast.TupleId(el), check_expr e2)
and check_typ t = { (*Work Here*)
    tname: t.Fast.tname;
    global_typs: List.map (fun gt -> check_typ gt) t.Fast.global_typs;
    global_fxns: [];
    global_stmts: check_stmt_list t.Fast.global_stmts;
    sub_typs: List.map (fun st -> check_sub_typ st) t.Fast.sub_typs;
  }
and check_sub_typ st = { (*Work Here*)
  typ: Typ(st.Fast.stname, (
    match st.Fast.oftyp with
    Some(el) -> None (*Work Here*)
    | None -> None
    ));
  nested_typs: List.map (fun nt -> check_typ nt) st.Fast.nested_typs;
  nested_fxns: [];
  nested_stmts: check_stmt_list st.Fast.nested_stmts;
}
and check_fxn f = { (*Work Here*)
  fname: f.Fast.fname;
  params: (

  );
  body: check_stmt_list sl;
}
