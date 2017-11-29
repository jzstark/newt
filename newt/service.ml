(*
 * Newt
 *)

(* definition of a service *)

type t =
 | I of int
 | F of float
 | S of string
 | Arr of Owl_dense_ndarray.arr

type s = IMAGE | TEXT | AUDIO | VIDEO

type proc = {
  mutable name   : string;
  mutable input  : t;
  mutable output : t;
  mutable func   : t -> t;
}
and service = { (*no, service should be a module...? *)
  mutable name : string;
  mutable gid : string;
  mutable ver : string;
  mutable typ : s;
  mutable entry : string option;
  mutable services : proc array;
}

(* DAG *)
type dag

(* load service from gist config file *)
val load  : string -> service (* deployer or here? *)

val load2 : string -> (service array * dag)

val run : service -> t
