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

(* functions to manipulate the service *)

(* load service from gist config file *)
val load  : string -> service (* deployer or here? *)

val load2 : string -> (service array * dag)

(* execute service *)
val run : service -> t

(*
let check m1 m2 =
  if (m1.output = m2.input) then true else false

let create () = {
  "default_name";
  "0";
  "0.0.1";
  []
}

let run method x =
  method.func x

let connect m1 m2 =
  assert (check m1 m2 = true);
  let s3 = create () in
  s3.name <- "new_service";
  s3.gist_id = "0";
  s3.version = "0.1";
  let new_func x =
    let output1 = run m1 x in
    let output2 = run m2 output1 in
    bar
  in
  let ss = [{"main", m1.input, m2.output, new_func}] in
  s3.services <- ss;
  s3
  *)
