open! Import
open! Map

let%test _ =
  invariants (of_increasing_iterator_unchecked (module Int) ~len:20 ~f:(fun x -> x,x))

let%test _ =
  invariants (Poly.of_increasing_iterator_unchecked ~len:20 ~f:(fun x -> x,x))

module M = M

let add12 t = add_exn t ~key:1 ~data:2

type int_map = int Map.M(Int).t [@@deriving compare, hash, sexp]

let%expect_test "[add_exn] success" =
  print_s [%sexp (add12 (empty (module Int)) : int_map)];
  [%expect {| ((1 2)) |}]
;;

let%expect_test "[add_exn] failure" =
  show_raise (fun () -> add12 (add12 (empty (module Int))));
  [%expect {| (raised ("[Map.add_exn] got key already present" (key 1))) |}]
;;

let%expect_test "[add] success" =
  print_s [%sexp (
    add (empty (module Int)) ~key:1 ~data:2 : int_map Or_duplicate.t)];
  [%expect {| (Ok ((1 2))) |}]
;;

let%expect_test "[add] duplicate" =
  print_s [%sexp (
    add (add12 (empty (module Int))) ~key:1 ~data:2 : int_map Or_duplicate.t)];
  [%expect {| Duplicate |}]
;;

let%expect_test "[Map.of_alist_multi] preserves value ordering" =
  print_s [%sexp (
    Map.of_alist_multi (module String) ["a", 1; "a", 2; "b", 1; "b", 3]
    : int list Map.M(String).t)];
  [%expect {|
    ((a (1 2))
     (b (1 3))) |}]
;;

let%expect_test "find_exn" =
  let map = Map.of_alist_exn (module String) ["one", 1; "two", 2; "three", 3] in
  let test_success key =
    require_does_not_raise [%here] (fun () ->
      print_s [%sexp (Map.find_exn map key : int)])
  in
  test_success "one";
  [%expect {| 1 |}];
  test_success "two";
  [%expect {| 2 |}];
  test_success "three";
  [%expect {| 3 |}];
  let test_failure key =
    require_does_raise [%here] (fun () ->
      Map.find_exn map key)
  in
  test_failure "zero";
  [%expect {| (Not_found_s ("Map.find_exn: not found" zero)) |}];
  test_failure "four";
  [%expect {| (Not_found_s ("Map.find_exn: not found" four)) |}];
;;

module Poly = struct
  let%test _ =
    length Poly.empty = 0
  ;;

  let%test _ =
    let a = Poly.of_alist_exn [] in
    Poly.equal Base.Poly.equal a Poly.empty
  ;;

  let%test _ =
    let a = Poly.of_alist_exn [("a", 1)] in
    let b = Poly.of_alist_exn [(1, "b")] in
    length a = length b
  ;;
end
