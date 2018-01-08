(* Simple example for event-based engines *)

(* #require netcgi2 and nethttpd *)

open Nethttpd_types
open Nethttpd_services
open Nethttpd_engine
open Printf

let resource = Hashtbl.create 2 (* string ("GET" or "POST"), (string, function) *)

let fn_handler fn env (cgi : Netcgi.cgi_activation) =
  (* A Netcgi-based content provider *)
  cgi # set_header
    ~cache:`No_cache
    ~content_type:"text/html; charset=\"iso-8859-1\""
    ();
  let input  = cgi # argument_value "data" in 
  let result = fn input in
  let data = result in 
    (*
    "<html>\n" ^
    "  <head><title>Easy Engine</title></head>\n" ^
    "  <body>\n" ^
    "    <a href='foo'>GET something</a><br>\n" ^
    "    <form method=POST encoding='form-data'>\n" ^
    "      <input type=hidden name=sample value='sample'>\n" ^
    "      <input type=submit value='POST something'>\n" ^
    "    </form>\n" ^
    "  </body>\n" ^
    "</html>" in
  *)
  cgi # output # output_string data;
  cgi # output # commit_work();
;;

(*
let srv =
  host_distributor
    [ default_host ~pref_name:"localhost" ~pref_port:8765 (),
      uri_distributor [ 
        "*", (options_service());
        "/plus", (
          dynamic_service { 
            dyn_handler = fn_handler (fun x -> x ^ " fuck!\n") ;
            dyn_activation = std_activation `Std_activation_buffered;
            dyn_uri = Some "/plus";
            dyn_translator = (fun _ -> "");
            dyn_accept_all_conditionals = false
         })
      ]
    ]
;;
*)

(* problems of general function type? *)
let add_endpoint res_name res_method res_fn = 
  let res_get = Hashtbl.find resource res_method in
  if not (Hashtbl.mem res_get res_name) then (
    Hashtbl.add res_get res_name res_fn;
    Hashtbl.replace resource res_method res_get;
  )

let delete_endpoint res_name res_method res_fn = None

let generate_srv () = 
  (* ip and port should come from config file *)
  let host = default_host ~pref_name:"localhost" ~pref_port:8765 () in
  let uri_list = ref [] in 

  let foo = fun (name, fn) ->
    let dy_fun = dynamic_service { 
      dyn_handler = fn_handler fn ;
      dyn_activation = std_activation `Std_activation_buffered;
      dyn_uri = Some ("/" ^ name);
      dyn_translator = (fun _ -> "");
      dyn_accept_all_conditionals = false
    } in
    uri_list := List.append !uri_list [(name, dy_fun)];
    ()
  in
  Hashtbl.iter foo (Hashtbl.find resource "GET");  (* what about post? *)
  let uri_dist = uri_distributor uri_list in
  host_distributor [host, uri_dist]


let serve_connection ues fd =
  (* Creates the http engine for the connection [fd]. When a HTTP header is received
   * the function [on_request_header] is called.
   *)
  printf "Connected\n";
  flush stdout;

  (* create new srv every time -- expensive *)
  let srv = generate_srv () in

  let config =
    new Nethttpd_engine.modify_http_engine_config
      ~config_input_flow_control:true
      ~config_output_flow_control:true
      Nethttpd_engine.default_http_engine_config 
  in
  let pconfig = new Nethttpd_engine.buffering_engine_processing_config in
  Unix.set_nonblock fd;
  ignore(Nethttpd_engine.process_connection config pconfig fd ues srv)
;;

let rec accept ues srv_sock_acc =
  (* This function accepts the next connection using the [acc_engine]. After the
   * connection has been accepted, it is served by [serve_connection], and the
   * next connection will be waited for (recursive call of [accept]). Because
   * [server_connection] returns immediately (it only sets the callbacks needed
   * for serving), the recursive call is also done immediately.
   *)
  let acc_engine = srv_sock_acc # accept() in
  Uq_engines.when_state ~is_done:(fun (fd,fd_spec) ->
			        if srv_sock_acc # multiple_connections then (
			          serve_connection ues fd;
			          accept ues srv_sock_acc
                                   ) else 
				  srv_sock_acc # shut_down())
                        ~is_error:(fun _ -> srv_sock_acc # shut_down())
                        acc_engine;
;;

let start() =
  (* We set up [lstn_engine] whose only purpose is to create a server socket listening
   * on the specified port. When the socket is set up, [accept] is called.
   *)
  printf "Listening on port 8765\n";
  flush stdout;
  let ues = Unixqueue.create_unix_event_system () in
  (* Unixqueue.set_debug_mode true; *)
  let opts = { Uq_server.default_listen_options with
		 Uq_server.lstn_backlog = 20;
		 Uq_server.lstn_reuseaddr = true } in
  let lstn_engine =
    Uq_server.listener
      (`Socket(`Sock_inet(Unix.SOCK_STREAM, Unix.inet_addr_any, 8765) ,opts)) ues in
  Uq_engines.when_state ~is_done:(accept ues) lstn_engine;
  (* Start the main event loop. *)
  Unixqueue.run ues
;;
let conf_debug() =
  (* Set the environment variable DEBUG to either:
       - a list of Netlog module names
       - the keyword "ALL" to output all messages
       - the keyword "LIST" to output a list of modules
     By setting DEBUG_WIN32 additional debugging for Win32 is enabled.
   *)
  let debug = try Sys.getenv "DEBUG" with Not_found -> "" in
  if debug = "ALL" then
    Netlog.Debug.enable_all()
  else if debug = "LIST" then (
    List.iter print_endline (Netlog.Debug.names());
    exit 0
  )
  else (
    let l = Netstring_str.split (Netstring_str.regexp "[ \t\r\n]+") debug in
    List.iter
      (fun m -> Netlog.Debug.enable_module m)
      l
  );
  if (try ignore(Sys.getenv "DEBUG_WIN32"); true with Not_found -> false) then
    Netsys_win32.Debug.debug_c_wrapper true
;;

Netsys_signal.init();
conf_debug();
start();;
