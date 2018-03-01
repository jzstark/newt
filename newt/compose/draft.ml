(* #require yojson *)

let conf_name = "service.json"

(* zoo_types.ml *)
type img = 
  | PPM of string
  | GEN of string

type text = 
  | CN of string
  | EN of string

type voice = 
  | EN of string
  | CN of string

(** tools for service developer *)
let string_of_img x = 
  match x with
  | PPM a -> a
  | GEN a -> a

let img_of_string x typ =
  match typ with
   | "ppm" -> PPM x
   | _     -> GEN x

let string_of_text x = 
  match x with
  | EN a -> a
  | CN a -> a

let text_of_string x typ = 
  match typ with
  | "EN" -> EN x
  | "CN" -> CN x

(** zoo_types.ml ends *)

type service = {
  mutable gists : string array;
  mutable types : string array;
  mutable graph : (string * string * int) Owl_graph.node; (* "M.f" * "gist" *)
}

let get_gists s = s.gists 
let get_types s = s.types
let get_graph s = s.graph

let in_types s = 
  let lst = Array.to_list (get_types s) in
  List.(lst |> rev |> tl |> rev) |> Array.of_list

let out_type s = 
  let lst = Array.to_list (get_types s) in
  List.(lst |> rev |> hd)

(** Helper function *)
let save_file file string =
  let channel = open_out file in
  output_string channel string;
  close_out channel

let strip_string s =
  Str.global_replace (Str.regexp "[\r\n\t ]") "" s

let filter_str (x, y) = x, 
  Yojson.Basic.Util.to_string y
  |> Str.split (Str.regexp "->")
  |> List.map strip_string

let uniq lst =
  let unique_set = Hashtbl.create (List.length lst) in
  List.iter (fun x -> Hashtbl.replace unique_set x ()) lst;
  Hashtbl.fold (fun x () xs -> x :: xs) unique_set []

(* split([1;2;3;4;5],3) --> [1;2;3], [4;5]*)
let split list n =
  let rec aux i acc = function
    | [] -> List.rev acc, []
    | h :: t as l -> 
      if i = 0 then List.rev acc, l
      else aux (i-1) (h :: acc) t in
  aux n [] list

let merge_array a b = 
  Array.append a b |> Array.to_list
  |> uniq |> Array.of_list

let replace a b idx = 
  assert (idx < (Array.length b));
  let x, y = split (Array.to_list b) idx in 
  (x @ (Array.to_list a) @ y) |> Array.of_list

let join ?(delim=" ") arr = 
  String.concat delim (Array.to_list arr)

(** Core functions *)

let make_snode name gist types = 
  let gists = [|gist|] in 
  let pn = Array.length types in
  let graph = Owl_graph.node (name, gist, pn) in 
  {gists; types; graph}

let make_services gist = 
  Owl_zoo_cmd.download_gist gist;
  let conf_json = Owl_zoo_cmd.load_file (gist ^ "/" ^ conf_name) in
  let nt_lst = Yojson.Basic.from_string conf_json
    |> Yojson.Basic.Util.to_assoc
    |> List.map filter_str 
  in
  let services = Array.make (List.length nt_lst) 
    (make_snode "" "" [|""|]) in
  List.iteri (fun i (n, t) -> 
    services.(i) <- make_snode n gist (Array.of_list t)
  ) nt_lst;
  services

(* Arbitrary args seems difficult to implement...? *)
let execute service args = ()

let save service name = ()
  let tmp_dir = Filename.get_temp_dir_name () ^ "/" ^
    (string_of_int (Random.int 100000)) in
  Sys.command "mkdir " ^ tmp_dir;

  generate_main ~dir:tmp_dir service name;
  generate_conf ~dir:tmp_dir service name;
  save_file (tmp_dir ^ "readme.md");
  let gist = Owl_zoo_cmd.upload_gist tmp_dir in (* to be added *)
  gist

let publish service mname =  
  let gist = save service mname in
  generate_server gist ^ "/" ^ conf_name;
  generate_dockerfile gist

let generate_server conf_file = ()

let generate_dockerfile gist = ()


(* generate service.json *)
let generate_conf ?(dir=".") service mname = 
  let name = String.capitalize_ascii mname ^ ".main" in
  let types = get_types service |> join ~delim:" -> " in
  let json = `Assoc [(name, `String types)] in

  let dir = if "." then Sys.getcwd () else dir in
  Yojson.Basic.to_file (dir ^ "/" ^ conf_name) json


(* generate a entry file called mname.ml based on service *)
let generate_main ?(dir=".") service mname = 
  let header = ref "" in 
  Array.iter (fun gist ->
    header := !header ^ (Printf.sprintf "#zoo \"%s\"\n" gist)
  ) (get_gists service);

  let p_num = Array.length (get_types service) in
  let params = Array.make p_num "" in
  for i = 0 to (p_num - 1) do 
    params.(i) <- "p" ^ (string_of_int i)
  done;
  let p_str = combine params in

  let body = ref "" in
  let cnt  = ref 0 in
  let pcnt = ref 0 in
  let iterfun node = 
    let name, gist, pn = Owl_graph.attr node in
    let ps = 
      let p_str' = combine (Array.sub params !pcnt pn) in
      if !cnt = 0 then p_str'
      else "r" ^ (string_of_int !cnt) ^ p_str'
    in
    body := !body ^ Printf.sprintf "  let r%d = %s %s in\n" !cnt name ps;
    pcnt := !pcnt + pn; cnt := !cnt + 1
  in
  Owl_graph.iter_ancestors iterfun [|(get_graph service)|];
  body := !body ^ (Printf.sprintf "  r%d\n" (!cnt - 1));

  let output_string = "#/usr/bin/env owl\n" ^ !header ^
    (Printf.sprintf "let main%s =\n%s" p_str !body) in 

  let dir = if "." then Sys.getcwd () else dir in
  save_file output_string (dir ^ "/" ^ mname ^ ".ml")


(** compose operations *)

(* "->" raise error if two services are not compatible *)

let seq ?(name="") s1 s2 idx = 
  (* manual type check *)
  assert (Array.mem (out_type s1) (in_types s2));
  let gists = merge_array (get_gists s1) (get_gists s2) in
  let types = replace (get_types s1) (get_types s2) idx in
  let graph = get_graph s1 in
  let graph_cld = get_graph s2 in 
  Owl_graph.connect [|graph|] [|graph_cld|];
  {gists; types; graph}

(* example *)

let s1 = make_snode
  "Squeezenet.infer"
  "aa36ee2c93fad476f4a46dc195b6fd89"
  [|"img"; "ndarray"|]

let s2 = make_snode
  "Squeezenet.to_json"
  "aa36ee2c93fad476f4a46dc195b6fd89"
  [|"ndarray"; "text"|]