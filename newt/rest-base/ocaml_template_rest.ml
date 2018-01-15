(*
  #require "lwt";
  #require "cohttp.lwt"
  #require "cohttp-lwt-unix"
*)

open Lwt
open Cohttp
open Cohttp_lwt_unix

let port = 8888 (* Sys.getenv "PORT" *)
let fn1  = Sqnet_example.infer_json
(* let fn1 ~top b = (string_of_int top) ^ b *)
let input_typ1 = [|"int"; "string"; "string"|]
let output_typ1 = "string"
let num_param1 = Array.length input_typ1

(*
 * Utility functions
 *)

let save_file file string =
  let channel = open_out file in
  output_string channel string;
  close_out channel

let syscall cmd =
  let ic, oc = Unix.open_process cmd in
  let buf = Buffer.create 16 in
  (try
     while true do
       Buffer.add_channel buf ic 1
     done
   with End_of_file -> ());
  let _ = Unix.close_process (ic, oc) in
  (Buffer.contents buf)

let encode_base64 filename =
  let cmd = "openssl base64 -in " ^ filename in
  syscall cmd

let decode_base64 bytestr filename =
  let tmp_byte = Filename.temp_file "tempbyte" ".b64" in
  save_file tmp_byte bytestr;
  let cmd = "openssl base64 -d -in " ^ tmp_byte ^ " -out " ^ filename in
  let _ = syscall cmd in
  ()
(*
 * Utility functions end
 *)

(* Problem: a general type inference. 
 * funx "10" "int" --> 10; funx "10" "float" --> 10.0 
 *)

(*
type t = I of int | F of float | S of string 

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

(* Toploop.mod_use_file Format.std_formatter "splus.ml" |> ignore; *)

let param_str uri =
  let params = Array.make num_param1 ("", "") in 
  Array.iteri (fun i t -> 
    let p = Uri.get_query_param uri ("input" ^ (string_of_int (i + 1))) in
    let p = match p with
      | Some x -> x
      | None   -> failwith "invalid input"
    in 
    params.(i) <- (t, p); ()
  ) input_typ1;
  params

let callback _conn req body =
  let uri = Request.uri req in
  match Uri.path uri with
    | "/predict/infer_json" ->
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
      let _, v3 = params.(2) in
      print_endline v1;
      print_endline v2;
      decode_base64 v3 v2; 
      let result = fn1 ~top:(int_of_string v1) v2 in (* it's already string format *)

      Server.respond_string ~status:`OK ~body:(result ^ "\n") ()
    | _ ->
      Server.respond_string ~status:`Not_found ~body:"Route not found" ()

let server =
  Server.create ~mode:(`TCP (`Port port)) (Server.make ~callback ())

let () = ignore (Lwt_main.run server)