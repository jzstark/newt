(*
 * Newt
 *)

(* definition of a service *)

type t =
 | I of int
 | F of float
 | S of string
 | Arr of Owl_dense_ndarray.arr

(* type s = IMAGE | TEXT | AUDIO | VIDEO *)

type s = {
  mutable name : string;
  mutable gid  : string;
  mutable ver  : string;
  mutable bottom : string;
  mutable entry : string option; (* the proc that is used to serve *)
  mutable input  : t;
  mutable output : t;
}

and service = {
  mutable ss : s array;
}

(* load service from gist config file *)
val load_atom : string -> service (* deployer or here? *)

(* val load_compound : string -> (service array * dag) *)

val run : service -> t
