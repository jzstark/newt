(*
 * Newt
 *)

(* definition of a service *)

type s = I of int | F of float

type ioformat = {
  mutable typ    : string;  (* "int", "Dense.Ndarray.S.arr", etc. *)
  mutable shape  : int list option;
  (* ?fmt    : data_format option; *)
  (* mutable dformat: data_format; *)
  mutable weight : string option;
}

type proc = {
  mutable name   : string;
  mutable input  : ioformat;
  mutable output : ioformat;
  mutable func   : s -> s;
}

type service = {
  mutable name    : string;
  mutable gist_id : string;
  mutable version : string;
  mutable services : proc list;
}



(*
type data_format =
  | Image
  | Text
  | Voice
  | None
*)


(* functions to manipulate the service *)

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

let unpack_int x =
  match x with
  | I a -> a
  | _ -> failwith "not a supported type"

let unpack_int x =
  match x with
  | F a -> a
  | _ -> failwith "not a supported type"
