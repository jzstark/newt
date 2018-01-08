(*
  #require "lwt";
  #require "cohttp.lwt"
  #require "cohttp-lwt-unix"
*)

open Lwt
open Cohttp
open Cohttp_lwt_unix

let port = 8888 (* Sys.argv.(1) -- how to pass parameter to this script? *)

(* Do I have to compile? *)
Toploop.mod_use_file Format.std_formatter "splus.ml" |> ignore;

let callback _conn req body =
  let uri = Cohttp.Request.uri req in
  match Uri.path uri with
    | "/predict" ->
      let param = Uri.get_query_param uri "data" in (* multiple data? think about an "int + int" service *)
      let param = match param with
        | Some x -> x
        | _      -> "No param supplied"
      in
      let resp  = Splus.plus param |> string_of_int in (*fun_name to fun; string_of_*? multiple output *)
      Server.respond_string ~status:`OK ~body:resp ()
    | _ ->
      Server.respond_string ~status:`Not_found ~body:"Route not found" ()

let server =
  Server.create ~mode:(`TCP (`Port port)) (Server.make ~callback ())

let () = ignore (Lwt_main.run server)