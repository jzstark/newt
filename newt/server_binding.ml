open Ctypes
open Foreign

(* How to get server_t type? *)
typedef server_t

(*
let t = abstract "resp_typ" 8 0
typedef t (function_t)(t);
*)

(* actually the type of input/output is not limitless *)
let function_t = ptr void @-> returning (ptr void)

let start_server = foreign "start" (string @-> int @-> returning (ptr server_t))
let add_endpoint = foreign "add_endpoint" (ptr server_t@ -> string @-> string @-> function_t @-> returning void)