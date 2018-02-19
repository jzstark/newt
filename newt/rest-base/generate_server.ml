open Yojson

let save_file file string =
  let channel = open_out file in
  output_string channel string;
  close_out channel

let filter_str (x, y) = x, Yojson.Basic.Util.to_string y

let _ = 

let json_lst = Yojson.Basic.from_file "service.json" 
    |> Yojson.Basic.Util.to_assoc
    |> List.map filter_str 
in

let f_str = ref "" in 

List.iteri (fun i (a, _) -> 
  f_str := !f_str ^ "let fn" ^ (string_of_int i) 
    ^ " = " ^ a ^ "\n"
) json_lst;

let output_string = 
"
open Lwt
open Cohttp
open Cohttp_lwt_unix

let port = 9527
" 
^ !f_str ^ 
"
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
  Unix.close_process (ic, oc);
  (Buffer.contents buf)

let encode_base64 filename =
  let cmd = \"openssl base64 -in \" ^ filename in
  syscall cmd

let decode_base64 bytestr filename =
  let tmp_byte = Filename.temp_file \"tempbyte\" \".b64\" in
  save_file tmp_byte bytestr;
  let cmd = \"openssl base64 -d -in \" ^ tmp_byte ^ \" -out \" ^ filename in
  syscall cmd

let param_str uri =
  let params = Array.make 10 (\"\", \"\") in
  Array.iteri (fun i t ->
    let p = Uri.get_query_param uri (\"input\" ^ (string_of_int (i + 1))) in
    let p = match p with
      | Some x -> x
      | None   -> failwith \"invalid input\"
    in
    params.(i) <- (t, p)
  ) [|\"\"; \"\"; \"\"|];
  params

let callback _conn req body =
  let uri = Request.uri req in
  match Uri.path uri with
  | \"/predict/infer_json\" ->
    let params = param_str uri in
    (* Hard-coded *)
    let _, v1 = params.(0) in (* image name *)
    let _, v2 = params.(1) in (* image b64 string *)
    let _, v3 = params.(2) in (* topN *)
    print_endline v3;
    print_endline v1;
    decode_base64 v2 v1; 
    let result = fn0 v1 |> fn1 ~top:(int_of_string v3) in
    Server.respond_string ~status:`OK ~body:(result ^ \"\n\") ()
  | _ ->
    Server.respond_string ~status:`Not_found ~body:\"Route not found\" ()

let server =
  Server.create ~mode:(`TCP (`Port port)) (Server.make ~callback ())

let () = ignore (Lwt_main.run server)
"

in

save_file "server.ml" output_string