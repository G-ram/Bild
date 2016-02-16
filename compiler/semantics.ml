open Sast
open Util

let rec check_literal scope = function
  Ast.Int(i) -> Int
  | Ast.Double(d) -> Double
  | Ast.String(s) -> String
  | Ast.Char(c) -> Char
  | Ast.Bool(b) -> Bool
  | Ast.Table(t) -> (
    match t with
      Ast.EmptyTable -> Table(Void)
      | Ast.ArrayLiteral(el) ->
        let el = check_exprs scope el in
        (*Make sure all the value are the same type*)
        let t = List.fold_left (fun ct (e, typ) ->
          is_typ_same ct typ
        ) (snd (List.hd el)) el in
        Table(t)
      | Ast.KeyValueLiteral(el) ->
        let el = List.map (fun (k, e) -> k, (check_expr scope e)) el in
        (*Make sure all the value are the same type*)
        let t = List.fold_left (fun ct (k, (e, typ)) ->
          is_typ_same ct typ
        ) (snd (snd (List.hd el))) el in
        Table(t)
    )
  | Ast.Tuple(el) -> Tuple((List.map
    (fun e -> snd e)
    (check_exprs scope el)
  ))

and check_exprs scope exprs = List.map (fun e -> check_expr scope e) exprs

and check_expr scope = function
  Ast.PrefixOp(op, e) ->
    let (e, typ) = check_expr scope e in
    (match typ with
       _ when (op = Ast.PreIncrement || op = Ast.PreDecrement || op = Ast.UMinus) && is_arith typ ->   PrefixOp(op, (e, typ)), typ
      | Bool when op = Ast.Negate -> PrefixOp(op, (e, typ)), typ
      | _ -> raise(Failure("prefix expression has invalid type"))
    )
  | Ast.TryPrefix(e1, e2) ->
    let (e1, typ1) = check_expr scope e1 in
    let (e2, typ2) = check_expr scope e2 in
    (match typ1 with
      Opt(t) -> TryPrefix((e1, typ1), (e2, typ2)), (is_typ_same t typ2)
      | _ -> raise(Failure("try expression is only valid for optional types"))
    )
  | Ast.Id(i) ->
    let v = (try
      (match find_var_and_scope scope (hash_id i) with
        RegTyp(n, t) -> Id(i), t
        | _ -> raise (Failure("identifier is either type specifier or function name; not permitted"))
      )
    with Not_found ->
      raise (Failure("undeclared identifier"))) in
    v
  | Ast.Literal(l) -> Literal(l), (check_literal scope l)
  | Ast.TableAccess(e, el) ->
    let (e, typ) = check_expr scope e in (*Check type and make sure not void*)
    let _ = (match is_void typ with
      false -> ()
      | _ -> raise(Failure("specifier is void"))
    ) in
    let el = check_exprs scope el in (*Check access expressions*)
    let ta = (match (is_id_like e), (is_string_ints el) with (*Check accessible and valid access types*)
      true, true -> TableAccess((e, typ), el), unwrap_typ el typ
      | _, _ -> raise(Failure("cannot access provided specifier"))
    ) in
    ta
  | Ast.TupleAccess(e, il) ->
    let (e, typ) = check_expr scope e in
    let (e, typ) = e, (
      match typ with
        Tuple(tl) ->
          let rec det_typ ctl (i :: cil) = (
              try (
                match (List.nth ctl i), (List.length cil) with
                  Tuple(ntl), _ -> det_typ ntl cil (*Found tuple element with more indices to eval*)
                  | t , 0 -> t (*Found some type on last index*)
                  | _, _ -> raise(Failure("too many dimensions specified for tuple access"))
                )
              with
                Invalid_argument(_) -> raise(Failure("trying to access element at negative index"))
                | Failure(_) -> raise(Failure("tuple index out of bounds exception"))
            )
          in det_typ tl il
        | _ -> raise(Failure("specifier is not tuple"))
      ) in
      let ta = TupleAccess((e, typ), il), typ in
      ta
  | Ast.TypeAccess(e, el) -> Literal(Ast.Int(5)), Int(*Work Here*)
  | Ast.Call(e, el) -> Literal(Ast.Int(5)), Int(*Work Here*)
  | Ast.PostfixOp(e, op) ->
    let (e, typ) = check_expr scope e in
    (match op with
      Ast.PostIncrement when is_arith typ ->
        PostfixOp((e, typ), op), typ
      | Ast.PostDecrement when is_arith typ ->
        PostfixOp((e, typ), op), typ
      | _ -> raise(Failure("postfix expression has invalid type"))
    )
  | Ast.BinOp(e1, op, e2) ->
    let (e1, typ1) = check_expr scope e1 in
    let (e2, typ2) = check_expr scope e2 in
    (match op with
      Ast.Plus -> BinOp((e1, typ1), op, (e2, typ2)), (is_cast typ1 typ2)
      | _ when is_arith typ1 && is_arith typ2 -> BinOp((e1, typ1), op, (e2, typ2)), (is_cast typ1 typ2)
      | _ -> raise(Failure("binary expression has invalid type(s)"))
    )
  | Ast.Assign(v, op, e) ->
    let (e, typ) = check_expr scope e in
    (match (is_assignable v), v, e with
      true, Ast.Id(id), _ -> (
          try
            let res = find_var_and_scope scope (hash_id id) in
            let vtyp = (match res with
              RegTyp(n, t) -> t
              | _ -> raise(Failure("trying to assign to a function or type"))
            ) in
            Assign((Id(id), vtyp), op, (e, typ)), is_typ_same typ vtyp
          with Not_found ->
            ignore(scope.variables <- (RegTyp(hash_id id, typ):: scope.variables)) ;
            VAssign((Id(id), typ), op, (e, typ)), typ
        )
      | true, t, _ -> let (v, vtyp) = check_expr scope t in (*Table and Tuple Assigment*) (*Work Here*)
        Assign((v, vtyp), op, (e, typ)), is_typ_same typ vtyp
      | _, _, _ -> raise(Failure("type is not assignable; found value, not variable"))
    )
  | Ast.MultiAssign(el1, op, el2) ->
    let typs = [] in
    let el = List.map2 (fun e1 e2 ->
        let (e, typ) = check_expr scope (Ast.Assign(e1, op, e2)) in ignore(typ :: typs) ; (e, typ)
      ) el1 el2 in
    MultiAssign(el), Tuple(typs)
  | Ast.TertiaryOp(e1, e2, e3) ->
    let (e1, typ1) = check_expr scope e1 in
    let (e2, typ2) = check_expr scope e2 in
    let (e3, typ3) = check_expr scope e3 in
    (match is_arith typ1 with
      true -> TertiaryOp((e1, typ1), (e2, typ2), (e3, typ3)), (is_typ_same typ2 typ3)
      | _ -> raise(Failure("predicate is not valid bool type"))
    )
  | Ast.Is(e1, e2) ->
    let (e1, typ1) = check_expr scope e1 in
    let (e2, typ2) = check_expr scope e2 in
    TryPrefix((e1, typ1), (e2, typ2)), (is_typ_same typ1 typ2)

let rec check_stmt scope = function
  Fast.Expr(e) -> Expr(check_expr scope e)
  | Fast.Block(sl) -> Block(check_stmts scope sl)
  | Fast.Conditional(s) -> Conditional(check_conditional_stmt scope s)
  | Fast.NestedTypeDeclarator(t) -> Empty (*Work Here*)
  | Fast.Print(e) -> Print(check_expr scope e)
  | Fast.Return(e) -> Return(check_expr scope e)
  | Fast.Raise(e) -> Raise(check_expr scope e)
  | Fast.Break -> Break
  | Fast.Empty -> Empty
and check_stmts scope sl = List.map (fun s -> check_stmt scope s) sl
and check_conditional_stmt scope = function
  Fast.If(e, sl, el) -> If(check_expr scope e, check_stmts scope sl, check_else_stmt scope el)
  | Fast.Try(sl1, e, sl2) -> Try(check_stmts scope sl1, check_expr scope e, check_stmts scope sl2)
  | Fast.While(e, sl) -> While(check_expr scope e, check_stmts scope sl)
  | Fast.For(e1, e2, e3, sl) -> For(check_expr scope e1, check_expr scope e2, check_expr scope e3, check_stmts scope sl)
  | Fast.ForIn(e1, e2, sl) -> ForIn(check_expr scope e1, check_expr scope e2, check_stmts scope sl)
  | Fast.Match(e, msl) -> Match(check_expr scope e, List.map (fun (m, sl) -> (check_match_conditional scope m, check_stmts scope sl)) msl)
and check_else_stmt scope = function
  Fast.ElIf(s) -> ElIf(check_conditional_stmt scope s)
  | Fast.Else(sl) -> Else(check_stmts scope sl)
and check_match_conditional scope = function
  Ast.MatchConditional(e, el) -> MatchConditional(check_expr scope e, check_expr scope (Ast.Id(Ast.TupleId(el))))
  | Ast.WhenMatchConditional(e1, el, e2) -> WhenMatchConditional(check_expr scope e1, check_expr scope (Ast.Id(Ast.TupleId(el))), check_expr scope e2)
(*and check_typ scope t = { (*Work Here*)
    tname: t.Fast.tname;
    global_typs: List.map (fun gt -> check_typ gt) t.Fast.global_typs;
    global_fxns: [];
    global_stmts: check_stmt scope_list t.Fast.global_stmts;
    sub_typs: List.map (fun st -> check_sub_typ st) t.Fast.sub_typs;
  }
and check_sub_typ scope st = { (*Work Here*)
  typ: Typ(st.Fast.stname, (
    match st.Fast.oftyp with
    Some(el) -> None (*Work Here*)
    | None -> None
    ));
  nested_typs: List.map (fun nt -> check_typ nt) st.Fast.nested_typs;
  nested_fxns: [];
  nested_stmts: check_stmt scope_list st.Fast.nested_stmts;
}
and check_fxn scope f ps = { (*Work Here*)
  fname: f.Fast.fname;
  params: (

  );
  body: (
    let sl = List.fold_left2 (fun p pi pe ->
      match p with
        Ast.TupleId(_) -> Ast.MultiAssign(pi, Ast.AEq, pe) :: p
        Ast.StdId(_) | Ast.OptId(_) -> Ast.Assign(pi, Ast.AEq, pe) :: p
        | _ -> raise(Failure("invalid parameter identifier"))
      ) [] f.Fast.params ps in List.concat sl f.Fast.body
    let b = check_stmt scope sl in b
    );
  return:;
}*)
