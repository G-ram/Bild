(* misc type checking functions *)
let rec find_var_and_scope (scope : Sast.symbol_table) name = try (
    List.find (fun s ->
      (match s with
        Sast.RegTyp(n, t) -> n == name
        | Sast.FxnTyp(n, t) -> n == name
        | Sast.TypeTyp(n, t, s2) -> n == name (*Work Here*)
      )
    ) scope.Sast.variables
  ) with Not_found ->
  match scope.Sast.parent with
    Some(parent) -> find_var_and_scope parent name
    | _ -> raise Not_found

let is_typ_same a b = match a, b with
  _, _ when a = b -> a
  | _, _ -> raise(Failure("type mismatch"))

let rec hash_id = function
  Ast.StdId(i) -> i
  | Ast.OptId(i) -> i
  | Ast.ForceId(i) -> i
  | _ -> ""

let rec is_assignable = function
  Ast.Id(_) -> true
  | Ast.TableAccess(_, _) -> true
  | Ast.TupleAccess(_, _) -> true
  | Ast.TypeAccess(_, el) -> is_assignable (List.hd (List.rev el))
  | _ -> false

let is_cast typ1 typ2 = match typ1, typ2 with
  _, _ when typ1 = typ2 -> typ1
  | _, _ when typ1 = Sast.String || typ2 = Sast.String -> Sast.String
  | Sast.Double, _ when typ2 = Sast.Int || typ2 = Sast.Char || typ2 = Sast.Bool -> Sast.Int
  | _, Sast.Double when typ2 = Sast.Int || typ1 = Sast.Char || typ1 = Sast.Bool -> Sast.Int
  | Sast.Int, _ when typ2 = Sast.Char || typ2 = Sast.Bool -> Sast.Int
  | _, Sast.Int when typ1 = Sast.Char || typ1 = Sast.Bool -> Sast.Int
  | _, _ -> raise(Failure("illegal cast"))

let is_arith = function
  Sast.Bool -> true
  | Sast.Int -> true
  | Sast.Double -> true
  | _ -> false

let rec is_void = function
  Sast.Table(t) -> is_void t
  | Sast.Void -> true
  | _ -> false

let unwrap_typ el t =
  let len = List.length el in
  let rec helper ct l = match ct, l with
    typ, 0 -> typ
    | Sast.Table(typ), x when x > 0 -> helper typ (x-1)
    | _, _ -> raise(Failure("table is not of dimension accessed"))
  in helper t len

let is_id_like = function
  Sast.Id(_) -> true
  | Sast.TableAccess(_, _) -> true
  | Sast.TypeAccess(_, _) -> true
  | Sast.TupleAccess(_, _) -> true
  | _ -> false

let is_string_int = function
  Sast.Int -> true
  | Sast.String -> true
  | _ -> false

let is_string_ints el = List.fold_left (
  fun t (e, typ) ->
    (is_string_int typ) && t
  ) true el

(* filters for fast list *)

let filter_typs stmts = List.filter (fun s ->
    match s with
      Fast.TypeDeclarator(_) -> true
      | _ -> false
  ) stmts

let filter_fxns stmts = List.filter (fun s ->
    match s with
      Fast.FxnDeclarator(_) -> true
      | _ -> false
  ) stmts

let build_scope stmts =
  (List.map (fun f -> Fast.Fxn(ref f)) (filter_fxns stmts)) @
  (List.map (fun t -> Fast.Typ(ref t)) (filter_typs stmts))
