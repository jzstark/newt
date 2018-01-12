(*
  #require "lwt";
  #require "cohttp.lwt"
  #require "cohttp-lwt-unix"
  #require "bitstring";;
  #require "base64";;
*)

open Lwt
open Cohttp
open Cohttp_lwt_unix

open B64
open Bitstring

let port = 8888 (* Sys.getenv "PORT" *)
let fn   = Splus.plus 
let input_typ = [|"int"; "string"|]
let output_typ = "int"
let num_param = Array.length input_typ

(* Problem: a general type inference. 
 * funx "10" "int" --> 10; funx "10" "float" --> 10.0 
 *)

(*
type t = I of int | F of float | S of string 

let unpack_int x =  
  match x with
  | I x -> x
  | _   -> failwith "error: Zoo.unpack_int"

let unpack_flt x =  
  match x with
  | F x -> x
  | _   -> failwith "error: Zoo.unpack_flt"

let unpack_str x =  
  match x with
  | S x -> x
  | _   -> failwith "error: Zoo.unpack_str"


let param_trans_input t inp = 
  match t with
  | "int"    -> I (int_of_string inp)
  | "float"  -> F (float_of_string inp)
  | "string" -> S inp (* deprecated *)
  | _        -> failwith "Illegal data type"

let param_trans_output t inp = 
  match t with
  | "int"    -> I (string_of_int inp)
  | "float"  -> F (string_of_float inp)
  | "string" -> S (inp)
  | _        -> failwith "Illegal data type"

*)

(* Do I have to compile? *)

(* Toploop.mod_use_file Format.std_formatter "splus.ml" |> ignore; *)

let param_str uri =
  let params = Array.make num_param ("", "") in 
  Array.iteri (fun i t -> 
    let p = Uri.get_query_param uri ("input" ^ (string_of_int (i + 1))) in
    let p = match p with
      | Some x -> x
      | None   -> failwith "invalid input"
    in 
    params.(i) <- (t, p); ()
  ) input_typ;
  params

let callback _conn req body =
  let uri = Cohttp.Request.uri req in
  match Uri.path uri with
    | "/predict" ->
      let params = param_str uri in
      (*
      let f = ref fn in
      Array.iter (fun t -> 
        let typ, str_v = t in 
        f := !f (param_trans_input typ str_v) 
      ) params;
      let result = !f |> param_trans_output output_typ in  *)


      (* Hard-coded *)
      let _, v1 = params.(0) in
      let _, v2 = params.(1) in
      let result = fn (int_of_string v1) v2 |> string_of_int in


      Server.respond_string ~status:`OK ~body:(result ^ "\n") ()
    | _ ->
      Server.respond_string ~status:`Not_found ~body:"Route not found" ()

let server =
  Server.create ~mode:(`TCP (`Port port)) (Server.make ~callback ())

let () = ignore (Lwt_main.run server)
