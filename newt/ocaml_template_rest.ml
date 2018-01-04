open Lwt.Infix
open Cohttp_lwt
open Cohttp_lwt_unix
open Cohttp_lwt_unix_io

open Splus (* user provide *)

let filename   = Sys.argv.(1)
let entry_func = Sys.argv.(2)

module Wm = struct
  module Rd = Webmachine.Rd
  include Webmachine.Make(Cohttp_lwt_unix_io)
end

(* May need to seperate this part out *)
class service = object(self)
  inherit [Cohttp_lwt_body.t] Wm.resource

  method allowed_methods rd =
    Wm.continue [`GET] rd

  method content_types_provided rd =
    Wm.continue [
      ("application/*", self#predict); (*user provide*)
    ] rd

  method content_types_accepted rd =
    Wm.continue [] rd

  method private predict rd =
    let json =
      (* user provide: type, name of file and function*)
      Printf.sprintf "{\"data\" : \"%s\"}" (Splus.plus rd) 
    in
    Wm.continue (`String json) rd
end

let main () =
  (* user provide: port *)
  let port = 8080 in
  let routes = [
    ("/predict", fun () -> new hello);
  ] in
  let callback (ch, conn) request body =
    let open Cohttp in
    Wm.dispatch' routes ~body ~request
    >|= begin function
      | Some result -> result
      | None        -> (`Not_found, Header.init (), `String "Not found", [])
    end
    >>= fun (status, headers, body, path) ->
      let path =
        match Sys.getenv "DEBUG_PATH" with
        | _ -> Printf.sprintf " - %s" (String.concat ", " path)
        | exception Not_found   -> ""
      in
      Printf.eprintf "%d - %s %s%s"
        (Code.code_of_status status)
        (Code.string_of_method (Request.meth request))
        (Uri.path (Request.uri request))
        path;
      Server.respond ~headers ~body ~status ()
  in
  let conn_closed (ch,conn) =
    Printf.printf "connection %s closed\n%!"
      (Sexplib.Sexp.to_string_hum (Conduit_lwt_unix.sexp_of_flow ch))
  in
  let config = Server.make ~callback ~conn_closed () in
  Server.create  ~mode:(`TCP(`Port port)) config >|= fun () ->
    Printf.eprintf "hello_lwt: listening on 0.0.0.0:%d%!" port

let () =  Lwt_main.run (main ())