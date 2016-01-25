open Sast

let rec find_var_and_scope (scope : symbol_table) name = try
  (List.find (fun (s, _) -> s = name) scope.variables) with Not_found ->
  match scope.parent with
    Some(parent) -> find_var_and_scope parent name
    | _ -> raise Not_found

let check_typ_same a b = match a, b with
  _, _ when a = b -> a
  | _, _ -> raise(Failure("type mismatch"))

let hash_id = function
    Id(i) -> i
    | OptId(i) -> i
    | TupleId(l) -> List.fold_left (
      fun t (i, _) ->
        let id = hash_id i in t ^ id
      ) "" l
    | Discard -> "_"
    | _ -> ""

let rec is_assignable = function
  Id(_) -> true
  | TableAccess(_, _) -> true
  | TupleAccess(_, _) -> true
  | TypeAccess(_, el) -> is_assignable (tl el)
  | _ -> false

let is_cast typ1 typ2 = match typ1, typ2 with
  _, _ when typ1 = typ2 -> typ1
  | _, _ when typ1 = String || typ2 = String -> String
  | Double, _ when typ2 = Int || typ2 = Char || typ2 = Bool -> Int
  | _, Double when typ2 = Int || typ1 = Char || typ1 = Bool -> Int
  | Int, _ when typ2 = Char || typ2 = Bool -> Int
  | _, Int when typ1 = Char || typ1 = Bool -> Int
  | _, _ -> raise(Failure("illegal cast"))

let is_arith = function
  Bool -> true
  | Int -> true
  | Double -> true
  | _ -> false
